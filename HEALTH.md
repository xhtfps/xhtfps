# 仓库体检（HEALTH）

> 由 `tools/health-check.ps1` 定时生成（2026-11-23 15:48），基于 `catalog.json`，只看硬指标。

## 1. 概览

| 指标 | 值 |
| --- | --- |
| 仓库数 | 25（公开 12 / 私有 13） |
| HEAD 体积合计 | 1,728 MB |
| 超 200 MB 的仓 | 2 个 |
| 超过 180 天未更新 | 0 个 |
| 没有 topics | 0 个 |
| README 只有标题 | 3 个 |

## 2. 体积红线（≥ 200 MB，按 HEAD 检出体积）

| 仓库 | HEAD 体积 | diskUsage | 建议 |
| --- | --- | --- | --- |
| [`stm32-cubemx-labs`](https://github.com/xhtfps/stm32-cubemx-labs) | 228 MB | 21 MB | 按 SLIM-PLAN.md 排期 |
| [`stm32f4-projects`](https://github.com/xhtfps/stm32f4-projects) | 219 MB | 42 MB | 按 SLIM-PLAN.md 排期 |

## 3. 长期未更新（≥ 180 天）

无。

## 4. 元数据缺失

- topics：全部仓库都有
- README 过薄：notes、shuweibei-cup-b2026、stm32-cubemx-labs

## 5. 处置入口

- 体积与历史：`SLIM-PLAN.md` + `tools/slim-history.ps1`
- topics 词表：`TOPICS.md` + `tools/set-topics.ps1`
- 索引与表格：`tools/build-index.ps1`（CI 每天重跑）
