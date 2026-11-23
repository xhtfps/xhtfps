#!/usr/bin/env python
"""semantic.py —— 在嵌入式库之上做「段落级」检索

为什么不是纯向量：本机下载 80 MB 以上的 embedding 模型会被网络截断（见
smart_robot/WEIGHTS.md 的实测），所以这里默认用 BM25（纯本地、零依赖），
并把 embedding 留成可选后端：

  python semantic.py build                     # 只建 BM25
  python semantic.py build --embedding          # 若装了 sentence-transformers 则加向量
  python semantic.py query "AD7606 过采样时序"
  python semantic.py query "PGA112 增益怎么设" -k 8

索引来源（全部本地，不联网）：
  1. embedded.db 的 docs / troubles / drivers / pins / usages 五张表；
  2. bsp-libs 下所有 *.md 按段落切块（驱动 README 的“取舍/前提”就在这）；
  3. notes/manuals.md 的手册台账行。

输出每条纹带 来源类型 + 位置 + 片段，能直接点回原文件。
"""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import sqlite3
import sys

# bge-small-zh-v1.5 只有 95 MB，中文检索强于同尺寸多语种模型，且本机能整包下载
EMB_MODEL = os.environ.get("EMB_MODEL", "BAAI/bge-small-zh-v1.5")
QUERY_PREFIX = "为这个句子生成表示以用于检索相关文章："

HERE = os.path.dirname(os.path.abspath(__file__))
IDX = os.path.dirname(HERE)                      # repos/idx
DB = os.path.join(IDX, "embedded.db")
OUT = os.path.join(IDX, "search-index.json")
ROOT = os.path.dirname(os.path.dirname(IDX))     # github-db
BSP = os.path.join(ROOT, "bsp-libs")
NOTES = os.path.join(ROOT, "notes")

TOKEN_RE = re.compile(r"[A-Za-z0-9_]+|[\u4e00-\u9fff]")


def tokens(text):
    return [t.lower() for t in TOKEN_RE.findall(text or "")]


def chunk_markdown(path, rel, max_chars=700):
    """按空行切段；过长的段再按句子切。返回 (source, location, text) 列表。"""
    out = []
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return out
    for block in re.split(r"\n\s*\n", text):
        block = block.strip()
        if len(block) < 20 or block.startswith("```"):
            continue
        # 表格整块按行拆：检索“增益怎么设”要能命中具体那一行，而不是整张表
        if block.count("|") >= 4 and "|---" in block.replace(" ", ""):
            for row in block.splitlines():
                if row.startswith("|") and "---" not in row and len(row.strip("| ")) > 4:
                    out.append((rel, "", row.strip()))
            continue
        while len(block) > max_chars:
            cut = block.rfind("。", 0, max_chars)
            if cut < 100:
                cut = max_chars
            out.append((rel, "", block[: cut + 1]))
            block = block[cut + 1:].lstrip()
        if block:
            out.append((rel, "", block))
    return out


def collect():
    entries = []
    con = sqlite3.connect(DB)
    con.row_factory = sqlite3.Row
    cur = con.cursor()

    for r in cur.execute("SELECT repo, category, chip, board, stack, status, description FROM repos"):
        txt = " ".join(str(r[k] or "") for k in ("repo", "category", "chip", "board", "stack", "status", "description"))
        entries.append({"source": "repo", "loc": r["repo"], "text": txt, "url": f"https://github.com/xhtfps/{r['repo']}"})

    for r in cur.execute("SELECT repo, path, state, url FROM docs"):
        entries.append({"source": "doc", "loc": f"{r['repo']}/{r['path']}", "text": r["path"],
                        "url": r["url"] or ""})

    for r in cur.execute("SELECT phenomenon, cause, repo, url FROM troubles"):
        entries.append({"source": "trouble", "loc": r["repo"], "text": f"{r['phenomenon']} {r['cause']}",
                        "url": r["url"] or ""})

    for r in cur.execute("SELECT id, name, interface, notes, source_repo, source_path FROM drivers"):
        entries.append({"source": "driver", "loc": f"drivers/{r['id']}",
                        "text": f"{r['name']} {r['interface']} {r['notes'] or ''}",
                        "url": f"https://github.com/xhtfps/bsp-libs/tree/main/drivers/{r['id']}"})

    for r in cur.execute("SELECT driver_id, board, net, mcu_pin, note FROM pins"):
        entries.append({"source": "pin", "loc": f"{r['board'] or 'driver-req'}/{r['net']}",
                        "text": f"{r['net']} {r['mcu_pin']} {r['note'] or ''}", "url": ""})

    for r in cur.execute("SELECT driver_id, repo, path FROM usages"):
        entries.append({"source": "usage", "loc": f"{r['repo']}/{r['path']}",
                        "text": f"{r['driver_id']} {r['path']}", "url": ""})
    con.close()

    if os.path.isdir(BSP):
        for dirpath, _, files in os.walk(BSP):
            for fn in files:
                if not fn.endswith(".md"):
                    continue
                full = os.path.join(dirpath, fn)
                rel = "bsp-libs/" + os.path.relpath(full, BSP).replace(os.sep, "/")
                for src, loc, text in chunk_markdown(full, rel):
                    entries.append({"source": "md", "loc": src, "text": text,
                                    "url": f"https://github.com/xhtfps/bsp-libs/blob/main/{rel[len('bsp-libs/'):]}"})

    manuals = os.path.join(NOTES, "manuals.md")
    if os.path.exists(manuals):
        for line in open(manuals, encoding="utf-8", errors="replace"):
            if line.startswith("|") and "---" not in line:
                entries.append({"source": "manual", "loc": "notes/manuals.md", "text": line.strip("| \n"),
                                "url": "https://github.com/xhtfps/notes/blob/main/manuals.md"})
    return entries


def build(use_embedding=False):
    entries = collect()
    docs = [tokens(e["text"]) for e in entries]
    df = {}
    for toks in docs:
        for t in set(toks):
            df[t] = df.get(t, 0) + 1
    n = len(docs)
    avg = sum(len(d) for d in docs) / max(n, 1)

    payload = {"n": n, "avgdl": avg, "df": df, "entries": []}
    for e, toks in zip(entries, docs):
        tf = {}
        for t in toks:
            tf[t] = tf.get(t, 0) + 1
        payload["entries"].append({**e, "len": len(toks), "tf": tf})

    if use_embedding:
        try:
            from sentence_transformers import SentenceTransformer  # noqa: PLC0415
        except Exception as exc:  # noqa: BLE001
            print(f"[warn] sentence-transformers 不可用（{exc}），只建 BM25：{exc}")
        else:
            model = SentenceTransformer(EMB_MODEL)
            vecs = model.encode([e["text"] for e in entries], normalize_embeddings=True, batch_size=32)
            payload["embedding_model"] = EMB_MODEL
            payload["vectors"] = [list(map(float, v)) for v in vecs]

    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False)
    print(f"写入 {OUT}：{n} 条，词表 {len(df)}，{os.path.getsize(OUT)/1024:.0f} KB"
          + ("，含向量" if payload.get("vectors") else "，仅 BM25"))


def bm25(payload, query, k):
    k1, b = 1.5, 0.75
    docs = payload["entries"]
    df, n, avg = payload["df"], payload["n"], payload["avgdl"]
    q = tokens(query)
    scored = []
    for i, d in enumerate(docs):
        s = 0.0
        for t in q:
            if t not in d["tf"]:
                continue
            idf = math.log(1 + (n - df.get(t, 0) + 0.5) / (df.get(t, 0) + 0.5))
            f = d["tf"][t]
            s += idf * f * (k1 + 1) / (f + k1 * (1 - b + b * d["len"] / avg))
        if s > 0:
            scored.append((s, i))
    scored.sort(reverse=True)
    return scored[:k]


def query(text, k=6):
    if not os.path.exists(OUT):
        print("还没有索引，先跑：python semantic.py build", file=sys.stderr)
        return 1
    payload = json.load(open(OUT, encoding="utf-8"))
    lexical = bm25(payload, text, k * 4)
    lex_norm = {i: s for s, i in lexical}
    lex_max = max(lex_norm.values()) if lex_norm else 1.0

    scores = {i: 0.4 * (s / lex_max) for i, s in lex_norm.items()}
    if payload.get("vectors"):
        try:
            from sentence_transformers import SentenceTransformer  # noqa: PLC0415
            import numpy as np  # noqa: PLC0415

            model = SentenceTransformer(payload["embedding_model"])
            qv = model.encode([QUERY_PREFIX + text], normalize_embeddings=True)[0]
            mat = np.asarray(payload["vectors"], dtype="float32")
            cos = mat @ np.asarray(qv, dtype="float32")
            top = {int(i): float(cos[i]) for i in cos.argsort()[::-1][: k * 4]}
            for i, c in top.items():
                scores[i] = scores.get(i, 0.0) + 0.6 * max(c, 0.0)
            mode = f"BM25 + {payload['embedding_model']} 向量（混合）"
        except Exception as exc:  # noqa: BLE001
            mode = f"仅 BM25（向量后端不可用：{exc}）"
    else:
        mode = "仅 BM25（索引里没有向量，用 build --embedding 补）"

    ranked = sorted(scores.items(), key=lambda kv: kv[1], reverse=True)[:k]
    if not ranked:
        print("没有命中，换更具体的词（芯片名、引脚、现象）")
        return 0
    print(f"查询：{text}\n模式：{mode}    索引 {payload['n']} 条\n")
    for i, score in ranked:
        d = payload["entries"][i]
        snippet = " ".join(d["text"].split())[:180]
        print(f"[{score:5.2f}] {d['source']:8s} {d['loc']}")
        print(f"        {snippet}")
        if d.get("url"):
            print(f"        {d['url']}")
        print()
    return 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build"); b.add_argument("--embedding", action="store_true")
    q = sub.add_parser("query"); q.add_argument("text"); q.add_argument("-k", type=int, default=6)
    a = ap.parse_args()
    if a.cmd == "build":
        build(a.embedding)
        return 0
    return query(a.text, a.k)


if __name__ == "__main__":
    raise SystemExit(main())
