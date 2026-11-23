# -*- coding: utf-8 -*-
"""
build-db.py —— 把索引仓的 catalog.json、bsp-libs 的 driver.json/pinmap.csv、
各仓 README 的排错段、notes 的移出台账，合成一个可查询的 SQLite：embedded.db

用法（需要 repo 权限 token）：
    $env:GITHUB_TOKEN = '...'
    python tools/build-db.py --owner xhtfps --out ../embedded.db

设计原则：
- 只读 GitHub REST，不改任何仓；
- 数据全部标注来源（repo/commit/url），错了一查就知道出处；
- 表结构固定，CI 每次重建，不增量更新（体积只有几百 KB）。
"""
import argparse, base64, json, os, re, sqlite3, sys, time
from datetime import datetime, timezone

import requests

API = 'https://api.github.com'
S = requests.Session()
S.trust_env = False          # 绕开本机代理（否则 TLS 中间人会随机 EOF）


def make_headers(token):
    h = {'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'}
    if token:
        h['Authorization'] = f'Bearer {token}'
    return h


def get(session_headers, path, params=None, tries=4):
    for i in range(tries):
        try:
            r = S.get(API + path, headers=session_headers, params=params, timeout=45)
            if r.status_code == 200:
                return r.json()
            if r.status_code == 404:
                return None
            if r.status_code in (403, 429):
                time.sleep(2 * (i + 1))
                continue
            raise RuntimeError(f'{r.status_code} {path}: {r.text[:120]}')
        except (requests.exceptions.RequestException, RuntimeError) as e:
            if i == tries - 1:
                raise
            time.sleep(2 * (i + 1))


def read_text_file(h, owner, repo, path):
    j = get(h, f'/repos/{owner}/{repo}/contents/{path}')
    if not j or 'content' not in j:
        return None
    return base64.b64decode(j['content']).decode('utf-8-sig', 'ignore')


def parse_pinmap(csv_text, board, drv_hint):
    rows = []
    if not csv_text:
        return rows
    lines = [l for l in csv_text.splitlines() if l.strip()]
    if not lines:
        return rows
    head = lines[0].split(',')
    idx = {name: i for i, name in enumerate(head)}
    for line in lines[1:]:
        parts = next(csv_parser(line), None)
        if not parts or len(parts) < 2:
            continue
        net = parts[idx.get('net', 1)].strip()
        if not net:
            continue   # 模板里的空占位行
        mcu_pin = parts[idx.get('mcu_pin', 2)].strip() if idx.get('mcu_pin', 2) < len(parts) else ''
        periph = parts[idx['peripheral']].strip() if 'peripheral' in idx and idx['peripheral'] < len(parts) else ''
        pin_name = parts[idx['pin_name']].strip() if 'pin_name' in idx and idx['pin_name'] < len(parts) else ''
        direction = parts[idx['direction']].strip() if 'direction' in idx and idx['direction'] < len(parts) else ''
        note = parts[idx['note']].strip() if 'note' in idx and idx['note'] < len(parts) else ''
        drv = drv_hint if drv_hint else net.split('_')[0].lower()
        rows.append(dict(driver_id=drv, board=board, net=net, mcu_pin=mcu_pin,
                         peripheral=periph, pin_name=pin_name, direction=direction, note=note))
    return rows


def csv_parser(line):
    """最小 CSV 解析：支持双引号包裹的字段与字段内逗号。"""
    buf, cur, in_q = [], '', False
    for ch in line:
        if ch == '"':
            in_q = not in_q
        elif ch == ',' and not in_q:
            buf.append(cur); cur = ''
        else:
            cur += ch
    buf.append(cur)
    yield [x.strip() for x in buf]


# 驱动在其它仓里的落点：按文件名关键字 + 头文件 include 关键字匹配
DRIVER_HINTS = {
    'ad9959': ['ad9959'],
    'ads1256': ['ads1256'],
    'mpu6050': ['mpu6050'],
}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--owner', default='xhtfps')
    ap.add_argument('--catalog', default='../catalog.json')
    ap.add_argument('--offload', default='../../../notes/offload.json')
    ap.add_argument('--trouble', default='../../../notes/troubleshooting.md')
    ap.add_argument('--out', default='../embedded.db')
    ap.add_argument('--token', default=os.environ.get('GITHUB_TOKEN', ''))
    args = ap.parse_args()

    here = os.path.dirname(os.path.abspath(__file__))
    def rp(p):
        return p if os.path.isabs(p) else os.path.normpath(os.path.join(here, p))

    h = make_headers(args.token)
    owner = args.owner

    catalog = json.load(open(rp(args.catalog), encoding='utf-8'))
    repos = {r['name']: r for r in catalog['repos']}

    def load_or_fetch(path, remote_repo, remote_path):
        """本地没有（CI 里 notes 仓不在工作区）就用 API 拉一份到临时文件。"""
        p = rp(path)
        if os.path.exists(p):
            return open(p, encoding='utf-8').read()
        text = read_text_file(h, owner, remote_repo, remote_path)
        if text is None:
            print(f'[warn] 取不到 {remote_repo}/{remote_path}，相关表将为空')
            return ''
        tmp = os.path.join(os.path.dirname(p) or '.', '_' + os.path.basename(p))
        open(tmp, 'w', encoding='utf-8').write(text)
        print(f'[info] 从远端取回 {remote_repo}/{remote_path} → {tmp}')
        return text

    offload_text = load_or_fetch(args.offload, 'notes', 'offload.json')
    trouble_md = load_or_fetch(args.trouble, 'notes', 'troubleshooting.md')
    offload = json.loads(offload_text) if offload_text.strip() else []

    out = rp(args.out)
    if os.path.exists(out):
        os.remove(out)
    con = sqlite3.connect(out)
    cur = con.cursor()
    cur.executescript('''
        CREATE TABLE repos(
            repo TEXT PRIMARY KEY, category TEXT, chip TEXT, board TEXT, stack TEXT,
            status TEXT, status_since TEXT, visibility TEXT, head_mb REAL, pushed_at TEXT,
            topics TEXT, description TEXT, html_url TEXT, readme_sections INTEGER, default_branch TEXT);
        CREATE TABLE drivers(
            id TEXT PRIMARY KEY, name TEXT, vendor TEXT, interface TEXT, supply TEXT,
            channels INTEGER, max_sps INTEGER, status TEXT, platform TEXT,
            source_repo TEXT, source_path TEXT, source_commit TEXT, notes TEXT);
        CREATE TABLE pins(
            driver_id TEXT, board TEXT, net TEXT, mcu_pin TEXT, peripheral TEXT,
            pin_name TEXT, direction TEXT, note TEXT,
            PRIMARY KEY(driver_id, board, net));
        CREATE TABLE docs(
            repo TEXT, path TEXT, size_kb INTEGER, state TEXT, base_commit TEXT, url TEXT,
            PRIMARY KEY(repo, path));
        CREATE TABLE troubles(
            n INTEGER PRIMARY KEY, phenomenon TEXT, cause TEXT, repo TEXT, section TEXT, url TEXT);
        CREATE TABLE usages(
            driver_id TEXT, repo TEXT, path TEXT, kind TEXT, PRIMARY KEY(driver_id, repo, path));
        CREATE TABLE meta(k TEXT PRIMARY KEY, v TEXT);
    ''')

    # 1) 仓库
    for name, r in repos.items():
        cur.execute('INSERT INTO repos VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', (
            name, r.get('category'), r.get('chip'), r.get('board'),
            ', '.join(r.get('stack') or []), r.get('status'), r.get('status_since'),
            r.get('visibility'), round((r.get('head_size_kb') or 0) / 1024, 1),
            r.get('pushed_at'), ', '.join(r.get('topics') or []),
            r.get('description'), r.get('html_url'), r.get('readme_sections'),
            r.get('default_branch')))

    # 2) 驱动 + 引脚
    bsp = repos.get('bsp-libs', {})
    bsp_branch = bsp.get('default_branch') or 'main'
    tree = get(h, f'/repos/{owner}/bsp-libs/git/trees/{bsp_branch}?recursive=1') or {'tree': []}
    drv_files = [t['path'] for t in tree['tree'] if t['type'] == 'blob']
    driver_ids = [p.split('/')[1] for p in drv_files if p.startswith('drivers/') and p.endswith('/driver.json')]
    for did in sorted(set(driver_ids)):
        dj = json.loads(read_text_file(h, owner, 'bsp-libs', f'drivers/{did}/driver.json') or '{}')
        req = dj.get('requires') or {}
        cur.execute('INSERT INTO drivers VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)', (
            dj.get('id', did), dj.get('name'), dj.get('vendor'), dj.get('interface'), dj.get('supply'),
            dj.get('channels'), dj.get('max_sample_rate_sps'), dj.get('status'),
            req.get('platform'), (dj.get('source') or {}).get('repo'),
            (dj.get('source') or {}).get('path'), (dj.get('source') or {}).get('commit'),
            dj.get('notes')))
        # 没接线的硬件要求先落一条 net 记录，board 留空
        for p in (req.get('pins') or []):
            cur.execute('INSERT OR IGNORE INTO pins VALUES(?,?,?,?,?,?,?,?)', (
                did, '', p.get('net'), '', '', '', p.get('direction', ''), p.get('note', '')))

    for p in drv_files:
        m = re.match(r'hardware/([^/]+)/pinmap\.csv$', p)
        if not m:
            continue
        board = m.group(1)
        text = read_text_file(h, owner, 'bsp-libs', p) or ''
        for row in parse_pinmap(text, board, ''):
            cur.execute('INSERT OR REPLACE INTO pins VALUES(?,?,?,?,?,?,?,?)', (
                row['driver_id'], row['board'], row['net'], row['mcu_pin'], row['peripheral'],
                row['pin_name'], row['direction'], row['note']))

    # 3) PDF（HEAD 现存）+ 已移出
    for name, r in repos.items():
        branch = r.get('default_branch') or 'main'
        t = get(h, f'/repos/{owner}/{name}/git/trees/{branch}?recursive=1')
        if not t:
            continue
        for node in t['tree']:
            if node['type'] != 'blob':
                continue
            path = node['path']
            low = path.lower()
            if low.endswith('.pdf'):
                cur.execute('INSERT OR REPLACE INTO docs VALUES(?,?,?,?,?,?)', (
                    name, path, int((node.get('size') or 0) / 1024), 'head', '',
                    f'https://github.com/{owner}/{name}/blob/{branch}/{requests.utils.quote(path)}'))
            # 4) 驱动落点
            base = os.path.basename(low)
            for did, hints in DRIVER_HINTS.items():
                if any(x in base for x in hints):
                    kind = 'source' if base.endswith(('.c', '.h')) else 'doc'
                    cur.execute('INSERT OR IGNORE INTO usages VALUES(?,?,?,?)', (did, name, path, kind))

    for x in offload:
        repo = x['repo'].split('/')[-1]
        cur.execute('INSERT OR REPLACE INTO docs VALUES(?,?,?,?,?,?)', (
            repo, x['path'], int(x.get('size', 0) / 1024), 'offloaded', x.get('base_commit', ''),
            f'https://github.com/{owner}/{repo}/blob/{x.get("base_commit","")}/{requests.utils.quote(x["path"])}'))

    # 5) 排错表（直接解析 notes 生成的 markdown 表格）
    n = 0
    for line in trouble_md.splitlines():
        if not line.startswith('| ') or line.startswith('| #') or line.startswith('| ---'):
            continue
        cells = [c.strip() for c in re.split(r'(?<!\\)\|', line)[1:-1]]
        if len(cells) < 5 or not cells[0].isdigit():
            continue
        n += 1
        repo = re.sub(r'\[`|`\]\(.*?\)', '', cells[3]).strip('`') or ''
        url = re.search(r'\((https?://[^)]+)\)', cells[3])
        cur.execute('INSERT INTO troubles VALUES(?,?,?,?,?,?)', (
            n, cells[1].replace('\\|', '|'), cells[2].replace('\\|', '|'),
            repo, cells[4], url.group(1) if url else ''))

    # 6) 元信息
    for k, v in [('built_at', datetime.now(timezone.utc).astimezone().strftime('%Y-%m-%d %H:%M %z')),
                 ('owner', owner), ('schema', '1')]:
        cur.execute('INSERT OR REPLACE INTO meta VALUES(?,?)', (k, v))

    con.commit()
    counts = {t: cur.execute(f'SELECT COUNT(*) FROM {t}').fetchone()[0]
              for t in ('repos', 'drivers', 'pins', 'docs', 'troubles', 'usages')}
    con.close()
    size = os.path.getsize(out)
    print(f'写完 {out}（{size/1024:.0f} KB）')
    print('  表行数：' + '，'.join(f'{k}={v}' for k, v in counts.items()))


if __name__ == '__main__':
    main()


