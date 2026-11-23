# -*- coding: utf-8 -*-
"""
link-check.py —— 扫各仓 README 里提到的文件名，判断它是否还在仓里。

判定四类（只有 B、C 算问题，会写进 LINKS.md 与 CI 输出）：
  A. 在本仓 HEAD 里
  B. 已被移到历史（在 notes/offload.json 台账里）——README 应改成台账链接，否则读者点开 404
  C. HEAD 没有、台账也没有——疑似死链（概括为“查无此文件”）
  D. 在本仓没有、但在别的仓有（跨仓引用，如 notes/offload.json、SLIM-PLAN.md）——只记录，不算问题

过滤：含 `*` 的通配写法、纯系统头（core_cm4.h / sys.h 这类不带路径的 .h）、
命令名（idf.py 等 .py 且不含路径）不检查，避免噪声淹没真问题。
"""
import base64, json, os, re, time
from collections import defaultdict
import requests

API = 'https://api.github.com'
S = requests.Session(); S.trust_env = False
TOKEN = os.environ.get('GITHUB_TOKEN', '')
H = {'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'}
if TOKEN:
    H['Authorization'] = f'Bearer {TOKEN}'

FILE_RE = re.compile(r'`([^`\n]{2,120}?\.(?:pdf|PDF|md|csv|h|c|ps1|py|json|xlsx|zip))`')
CHECK_EXT = {'pdf', 'md', 'csv', 'xlsx', 'zip', 'json'}
SKIP_TOKENS = {'idf.py', 'sys.h', 'core_cm4.h', 'core_cm7.h', 'core_cm3.h'}


def api(path, tries=4):
    for i in range(tries):
        try:
            r = S.get(API + path, headers=H, timeout=40)
            if r.status_code == 404:
                return None
            if r.status_code != 200:
                time.sleep(2 * (i + 1)); continue
            return r.json()
        except requests.exceptions.RequestException:
            if i == tries - 1:
                raise
            time.sleep(2 * (i + 1))


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    owner = 'xhtfps'
    ledger_path = os.path.normpath(os.path.join(here, '../../../notes/offload.json'))
    ledger = json.load(open(ledger_path, encoding='utf-8')) if os.path.exists(ledger_path) else []
    offloaded = defaultdict(set)
    for x in ledger:
        offloaded[x['repo'].split('/')[-1]].add(os.path.basename(x['path']).lower())

    # 仓列表优先读本地 catalog.json（少一次 API、也避免 /user/repos 抖动）
    cat_path = os.path.normpath(os.path.join(here, '..', 'catalog.json'))
    cat = json.load(open(cat_path, encoding='utf-8'))
    repos = [{'name': r['name'], 'default_branch': r.get('default_branch') or 'main'}
             for r in cat['repos'] if r['name'] != 'xhtfps']

    trees, readmes = {}, {}
    global_files = set()
    for r in repos:
        name, branch = r['name'], r['default_branch']
        t = api(f'/repos/{owner}/{name}/git/trees/{branch}?recursive=1') or {'tree': []}
        paths = {n['path'] for n in t['tree'] if n['type'] == 'blob'}
        trees[name] = (paths, {os.path.basename(p).lower() for p in paths})
        global_files |= trees[name][1]
        rd = api(f'/repos/{owner}/{name}/readme')
        if rd and 'content' in rd:
            readmes[name] = base64.b64decode(rd['content']).decode('utf-8', 'ignore')
    # 索引仓自身也算跨仓可解析
    idx_files = {os.path.basename(p).lower() for p in os.listdir(os.path.normpath(os.path.join(here, '..')))}
    global_files |= idx_files

    report = []
    for name, text in readmes.items():
        own = trees[name][1]
        for m in FILE_RE.finditer(text):
            token = m.group(1).strip()
            if '*' in token or token.lower() in SKIP_TOKENS:
                continue
            ext = token.rsplit('.', 1)[-1].lower()
            base = os.path.basename(token.replace('\\', '/')).lower()
            if ext in CHECK_EXT:
                pass
            elif ext in ('c', 'h') and ('drive_' in base or base.startswith(('ad9959', 'ads1256', 'mpu6050', 'i2c'))):
                pass
            else:
                continue
            if base in own:
                state = 'ok'
            elif base in global_files:
                state = 'cross'
            elif base in offloaded[name]:
                state = 'offloaded'
            else:
                state = 'missing'
            report.append({'repo': name, 'token': token, 'state': state})

    issues = [x for x in report if x['state'] in ('offloaded', 'missing')]
    out_md = os.path.normpath(os.path.join(here, '..', 'LINKS.md'))
    lines = ['# README 引用体检（LINKS）', '',
             '> 由 `tools/link-check.py` 扫描各仓 README 反引号里的文件名，判断是否仍在分支 HEAD 中；CI 每天重跑。',
             '> `已移出`：文件已进历史台账，README 该改成 `notes/manuals.md` 链接；`查无此文件`：HEAD 与台账都没有，属疑似死链。', '',
             f'共解析 {len(report)} 处引用（跨仓引用 {len([x for x in report if x["state"]=="cross"])} 处已自动放行），'
             f'**问题 {len(issues)} 处**。', '',
             '| 仓库 | README 里写的 | 判定 |', '| --- | --- | --- |']
    for x in sorted(issues, key=lambda y: (y['state'], y['repo'])):
        tag = '已移出' if x['state'] == 'offloaded' else '查无此文件'
        lines.append(f'| {x["repo"]} | `{x["token"]}` | {tag} |')
    if not issues:
        lines.append('| — | 无 | — |')
    open(out_md, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    json_out = os.path.normpath(os.path.join(here, '..', 'links.json'))
    open(json_out, 'w', encoding='utf-8').write(json.dumps(
        {'checked': len(report), 'issues': issues}, ensure_ascii=False, indent=2))
    print(f'写完 {out_md}：解析 {len(report)} 处，问题 {len(issues)} 处')
    for x in issues:
        print(f'  [{x["state"]}] {x["repo"]}: {x["token"]}')

if __name__ == '__main__':
    main()

