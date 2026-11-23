# -*- coding: utf-8 -*-
"""
db.py —— 查 embedded.db 的命令行入口。

用法：
    python tools/db.py stats
    python tools/db.py repo ads            # 按关键词查仓（名字/芯片/板卡/技术栈/topics）
    python tools/db.py driver ads1256      # 驱动详情 + 各板引脚
    python tools/db.py pin PF4             # 按 MCU 引脚或网名反查
    python tools/db.py doc 手册            # 查 PDF（默认只查仍在仓内的，--all 含已移出）
    python tools/db.py trouble J-Link      # 查排错速查
    python tools/db.py usage ad9959        # 这颗芯片/驱动在哪些仓里出现过
    python tools/db.py sql "select ..."    # 直接 SQL
    任意命令加 --json 输出机器可读结果

库默认取本脚本同目录的 ../embedded.db；也可 --db 指定。
"""
import argparse, json, os, sqlite3, sys, textwrap

COLS = {'repo': ['repo', 'category', 'chip', 'board', 'status', 'head_mb', 'pushed_at']}


def connect(path):
    if not os.path.exists(path):
        sys.exit(f'找不到数据库：{path}\n先跑 tools/build-db.py 生成，或从 '
                 f'https://github.com/xhtfps/xhtfps 的 embedded.db 下载。')
    con = sqlite3.connect(path)
    con.row_factory = sqlite3.Row
    return con


def show(rows, cols, json_out):
    if json_out:
        print(json.dumps([dict(r) for r in rows], ensure_ascii=False, indent=2))
        return
    if not rows:
        print('（无结果）')
        return
    widths = {c: max(len(c), *(len(str(r[c] or '')) for r in rows)) for c in cols}
    widths = {c: min(w, 40) for c, w in widths.items()}
    print('  '.join(c.ljust(widths[c]) for c in cols))
    print('  '.join('-' * widths[c] for c in cols))
    for r in rows:
        cells = []
        for c in cols:
            v = str(r[c] or '')
            cells.append((v[:38] + '…' if len(v) > 40 else v).ljust(widths[c]))
        print('  '.join(cells))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['stats', 'repo', 'driver', 'pin', 'doc', 'trouble', 'usage', 'sql'])
    ap.add_argument('arg', nargs='?', default='')
    ap.add_argument('--db', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'embedded.db'))
    ap.add_argument('--json', action='store_true')
    ap.add_argument('--all', action='store_true', help='doc：连已移出的一起查')
    a = ap.parse_args()
    con = connect(a.db)
    cur = con.cursor()
    kw = a.arg
    like = f'%{kw}%'

    if a.cmd == 'stats':
        rows = []
        for t in ('repos', 'drivers', 'pins', 'docs', 'troubles', 'usages'):
            rows.append({'table': t, 'rows': cur.execute(f'select count(*) from {t}').fetchone()[0]})
        rows.append({'table': 'meta:built_at', 'rows': cur.execute("select v from meta where k='built_at'").fetchone()[0]})
        show(rows, ['table', 'rows'], a.json)

    elif a.cmd == 'repo':
        rows = cur.execute('''select repo, category, chip, board, status, head_mb, pushed_at
                              from repos where repo like ? or chip like ? or board like ? or stack like ?
                              or topics like ? or description like ? order by head_mb desc''',
                           (like, like, like, like, like, like)).fetchall()
        show(rows, COLS['repo'], a.json)

    elif a.cmd == 'driver':
        rows = cur.execute('''select id, name, vendor, interface, status, source_repo, source_path
                              from drivers where id like ? or name like ? or interface like ?''',
                           (like, like, like)).fetchall()
        show(rows, ['id', 'name', 'vendor', 'interface', 'status', 'source_repo'], a.json)
        if not a.json:
            for r in rows:
                pins = cur.execute('''select board, net, mcu_pin, direction, note from pins
                                      where driver_id=? order by board, net''', (r['id'],)).fetchall()
                print(f'\n[{r["id"]}] 引脚（board 为空表示未接线，只是驱动要求）：')
                show(pins, ['board', 'net', 'mcu_pin', 'direction', 'note'], False)

    elif a.cmd == 'pin':
        rows = cur.execute('''select driver_id, board, net, mcu_pin, direction, note from pins
                              where mcu_pin like ? or net like ? order by mcu_pin''', (like, like)).fetchall()
        show(rows, ['driver_id', 'board', 'net', 'mcu_pin', 'direction', 'note'], a.json)

    elif a.cmd == 'doc':
        q = '''select repo, path, size_kb, state, url from docs
               where (path like ? or repo like ?)'''
        if not a.all:
            q += " and state='head'"
        rows = cur.execute(q + ' order by size_kb desc', (like, like)).fetchall()
        show(rows, ['repo', 'path', 'size_kb', 'state'], a.json)
        if not a.json and rows:
            print(f'\n共 {len(rows)} 条。取文件：state=head 直接点 url；state=offloaded 的 url 指向移出前提交。')

    elif a.cmd == 'trouble':
        rows = cur.execute('''select phenomenon, cause, repo, section from troubles
                              where phenomenon like ? or cause like ? or repo like ?''',
                           (like, like, like)).fetchall()
        show(rows, ['phenomenon', 'cause', 'repo', 'section'], a.json)

    elif a.cmd == 'usage':
        rows = cur.execute('''select repo, path, kind from usages where driver_id like ?
                              order by repo''', (like,)).fetchall()
        if not a.json:
            rows = sorted(rows, key=lambda r: (r['repo'] != 'bsp-libs', r['repo']))
        show(rows, ['repo', 'path', 'kind'], a.json)

    elif a.cmd == 'sql':
        try:
            rows = cur.execute(kw).fetchall()
        except Exception as e:
            sys.exit(f'SQL 出错：{e}')
        if rows:
            show(rows, list(rows[0].keys()), a.json)
        else:
            print('（无结果）')

    con.close()


if __name__ == '__main__':
    main()
