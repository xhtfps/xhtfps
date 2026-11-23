#!/usr/bin/env python3
"""把 catalog.json + embedded.db 导出成站点用的 docs/data.json。

只导出**公开仓**的数据：私有仓的名字、描述、引脚、排错条目一律不写入，
因为 GitHub Pages 是公开可访问的。要在本地看全量，加 --include-private，
输出到 docs/data-private.json（该文件已在 .gitignore 里，不会进仓）。
"""
import argparse
import json
import sqlite3
import sys
from datetime import datetime, timezone

PUBLIC_KEYS = ('name', 'category', 'chip', 'board', 'stack', 'status',
               'description', 'topics', 'html_url', 'size_kb', 'language',
               'license', 'pushed_at', 'peripherals')


def load(con, table):
    con.row_factory = sqlite3.Row
    return [dict(r) for r in con.execute(f'select * from "{table}"')]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--catalog', default='catalog.json')
    ap.add_argument('--db', default='embedded.db')
    ap.add_argument('--out', default='docs/data.json')
    ap.add_argument('--include-private', action='store_true')
    a = ap.parse_args()

    con = sqlite3.connect(a.db)
    meta = {r['k']: r['v'] for r in load(con, 'meta')}
    repos_all = load(con, 'repos')
    catalog = json.load(open(a.catalog, encoding='utf-8'))

    cat_by_name = {r['name']: r for r in catalog['repos']}
    public = [] if a.include_private else [
        r['repo'] for r in repos_all if r['visibility'] == '公开']
    vis = {r['repo']: r['visibility'] for r in repos_all}

    def keep(repo):
        return a.include_private or repo in public

    repos = []
    for r in repos_all:
        if not keep(r['repo']):
            continue
        c = cat_by_name.get(r['repo'], {})
        item = {k: c.get(k) for k in ('name', 'category', 'chip', 'board', 'stack',
                                     'status', 'description', 'topics', 'size_kb',
                                     'language', 'license', 'pushed_at')}
        item['peripherals'] = c.get('peripherals', [])
        item['html_url'] = r['html_url']
        item['visibility'] = r['visibility']
        item['head_mb'] = r['head_mb']
        item['default_branch'] = r['default_branch']
        repos.append(item)

    drivers_all = load(con, 'drivers')
    drivers = [d for d in drivers_all if keep(d['source_repo'])]
    d_ids = {d['id'] for d in drivers}

    pins_all = load(con, 'pins')
    pins = [p for p in pins_all if p['driver_id'] in d_ids]

    docs_all = load(con, 'docs')
    docs = [d for d in docs_all if keep(d['repo'])]

    troubles_all = load(con, 'troubles')
    troubles = [t for t in troubles_all if keep(t['repo'])]

    usages_all = load(con, 'usages')
    usages = [u for u in usages_all if keep(u['repo']) and u['driver_id'] in d_ids]

    payload = {
        'meta': {
            'owner': meta.get('owner', catalog.get('owner')),
            'db_built_at': meta.get('built_at', ''),
            'catalog_generated_at': catalog.get('generated_at', ''),
            'exported_at': datetime.now(timezone.utc).astimezone().strftime('%Y-%m-%d %H:%M %z'),
            'scope': 'all' if a.include_private else 'public-only',
            'schema': meta.get('schema', '1'),
            'counts': {
                'repos': len(repos), 'drivers': len(drivers), 'pins': len(pins),
                'docs': len(docs), 'troubles': len(troubles), 'usages': len(usages),
                'repos_all': len(repos_all),
            },
        },
        'repos': repos,
        'drivers': drivers,
        'pins': pins,
        'docs': docs,
        'troubles': troubles,
        'usages': usages,
    }

    with open(a.out, 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, separators=(',', ':'))
    c = payload['meta']['counts']
    print(f'wrote {a.out}: scope={payload["meta"]["scope"]} '
          f'repos={c["repos"]}/{c["repos_all"]} drivers={c["drivers"]} pins={c["pins"]} '
          f'docs={c["docs"]} troubles={c["troubles"]} usages={c["usages"]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
