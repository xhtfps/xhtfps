# 大仓瘦身（SLIM-PLAN · 已执行两轮）

结论先说：**全库 HEAD 已从 2,933 MB 降到 1,728 MB（−41%），超 200 MB 的仓从 7 个降到 2 个。** 原定的“1.2 GB 以内”在**不重写历史**的前提下不可达——剩下的体积是各工程自带的 HAL/CMSIS 副本，删掉工程就编不动。要再往下只有“抽公共库”或“history rewrite”两条路，见 §5。

## 1. 已执行清单（普通提交，历史保留，可恢复）

每一条移出的文件都记在 [`notes/offload.json`](https://github.com/xhtfps/notes/blob/main/offload.json)（`repo / path / size / base_commit`），打开 `https://github.com/xhtfps/<repo>/blob/<base_commit>/<path>` 就能取回原文件。

### 第一轮（2,933 → 2,038 MB）

| 仓库 | 移出内容 | 省下 | 提交 |
| --- | --- | --- | --- |
| `zynq-navigator-board` | Vivado 产物 5,345 个（`.ip_user_files/`、`.runs/`、`.cache/`、`.sim/`、`.hw/`、`.gen/`、`.rpx/.jou/.log/.dcp/.wdb`） | 132.1 MB | `3a8be384` |
| `zynq-navigator-board` | PDF 89 个（芯片手册、教程） | 296.0 MB | `0be70b2a` |
| `stm32f407-board-materials` | PDF 133 个（硬件资料目录） | 189.7 MB | `785919ed` |
| `stm32f4-reference-materials` | LVGL `demos/` 副本 | 122.0 MB | `5c246df0` |
| `stm32f4-reference-materials` | PDF 16 个 | 53.9 MB | `7105517a` |
| `smart_robot` | Python `venv` | 38.5 MB | `7c625509` |
| `stm32-cubemx-labs` | CMSIS 重复副本 | 13.0 MB | `91daec0d` |
| `stm32-cubemx-labs` | 逐文件清单 `EXCLUDED_MANIFEST.csv`（10 MB）改摘要 | 10.0 MB | `91daec0d` |
| `electronics-competition` | 历史拷贝 `.zip` 与 `uvguix` 垃圾 | 6.9 MB | `cf9f7b00` |
| `shuweibei-cup-b2026` | 重复输出 PDF 69 个 | 60.5 MB | `04801294` |

> 插曲：`shuweibei` 这一轮误删了 `problem_4_timelines.csv`，已从父提交取回 blob 加回（`2d6d416f`）。这件事顺带验证了恢复路径：**任何被 trim 掉的文件，都能从该提交的父提交拿 blob SHA 重新挂回树**。

### 第二轮（2,038 → 1,728 MB）

| 仓库 | 移出内容 | 省下 | 提交 |
| --- | --- | --- | --- |
| `stm32f4-projects` | 参考资料 PDF 15 个 | 31.0 MB | `09a78eb9` |
| `electronics-competition` | ST StdPeriph 库 3,150 个文件（ST 官网可重下，模板代码保留） | 79.0 MB | `a2ab4a6e` |
| `smart_robot` | `firefly_e10_s1110.pth`（81.1 MB）、`yolo26s.pt`×2（各 19.5 MB）、`pcd_data` 图片集（约 80 MB） | 200.1 MB | `fa24a3db` |

台账共 **278 条**：253 个 PDF + 25 个非 PDF 资产（`smart_robot` 的权重与 `pcd_data` 数据集，`kind=trim`），后者用 `notes/tools/fetch-assets.py` 一条命令取回。

## 2. 现在的体积（HEAD 检出体积，`git/trees` blob 求和）

| 仓库 | 瘦身前 | 现在 | 还剩什么 |
| --- | --- | --- | --- |
| `stm32-cubemx-labs` | 241 MB | **228 MB** | 6 个 lab 各带一份 HAL/CMSIS |
| `stm32f4-projects` | 250 MB | **219 MB** | 各工程自带 CMSIS + 旧工程 `.hex/.map` |
| `stm32f4-reference-materials` | 375 MB | **200 MB** | FreeRTOS 模板、Altium 工程 |
| `freertos-labs` | 142 MB | 142 MB | 每 lab 一份 HAL |
| `electronics-competition` | 218 MB | 132 MB | 工程与模板 |
| `shuweibei-cup-b2026` | 171 MB | 129 MB | 论文与支撑材料（用户成果，不删） |
| `stm32f407-board-materials` | 294 MB | 104 MB | 程序源码 |
| `zynq-navigator-board` | 480 MB | 52 MB | 源码与文档 |
| `smart_robot` | 291 MB | 52 MB | 代码与配置 |
| 全库合计 | 2,933 MB | **1,728 MB** | 超 200 MB：2 个 |

体积口径：`head_size_kb` 来自 `git/trees?recursive=1` 对 blob 求和，是“clone 下来占多少”。`diskUsage` 要等 GitHub GC（几小时到一天），别用它判断瘦身效果。

## 3. 取舍原则（这几条决定了哪些没删）

1. **用户自己的成果不删**：论文、题目、报告、答辩材料（`shuweibei` 25 页论文、`electronics` G 题论文）一律留，哪怕它大。
2. **厂商手册出仓**：芯片手册、板级原理图、教程 PDF 进 `notes/manuals.md` 台账，仓里不留。
3. **上游可重下的可删**：ST StdPeriph、上游预训练权重、LVGL `demos/`——能从官网/上游仓库再拿到的，删了只是多跑一次下载。
4. **工程产物与依赖必删**：Vivado `.runs/.cache`、`venv`、`node_modules`、`uvguix`，这些从来不该进仓。
5. **工程可编译性优先**：工程自带的 `Drivers/` 是它独立编译的前提，不因省体积而破坏。这也是停在 1,728 MB 的原因。
6. **不 rewrite**：本次全部走普通提交，旧 SHA 有效，`--mirror` 备份都不需要。

## 4. 可复用命令（本次实际用的就是这三条）

```powershell
# 环境准备：绕开系统代理（本机 7897 端口有 TLS 中间人，会随机 EOF）
$env:NO_PROXY='*'; Remove-Item Env:HTTP_PROXY,Env:HTTPS_PROXY,Env:ALL_PROXY -ErrorAction SilentlyContinue
$c = ("protocol=https`nhost=github.com`n`n" | git credential fill) -split "`n"
$env:GITHUB_TOKEN = (($c | Where-Object { $_ -like 'password=*' }) -replace '^password=','')

# 1) PDF 移出仓并记账（会追加写 notes/offload.json）
D:\conda\envs\robot-pose\python.exe tools\offload_pdfs.py --repos <repo> --ledger notes\offload.json
#    先看会删什么：加 --dry-run

# 2) 按路径/扩展名移出（正则，支持多模式与 --dry-run）
D:\conda\envs\robot-pose\python.exe tools\gh_tool.py trim --repo <repo> --message "<提交说明>" --include '\.pth$' 'pcd_data/'

# 3) 重算体积与体检
pwsh -File repos\idx\tools\build-index.ps1 -Token $env:GITHUB_TOKEN
pwsh -File repos\idx\tools\health-check.ps1
```

## 5. 要再往下压，只剩两条路（都未执行）

**A. 抽公共库（推荐，无需重写历史）**
把 `freertos-labs`、`stm32-cubemx-labs`、`stm32f4-projects` 里重复的 HAL/CMSIS 收进 `bsp-libs` 的 `vendor/` 子模块或 Release 包，各仓改用脚本拉取。预期再省 300–400 MB，代价是这 3 个仓的“clone 即编译”要改成“跑一次 `tools/fetch-vendor.ps1`”。

**B. history rewrite（要 `force push`，不可逆）**
```powershell
git clone --mirror https://github.com/xhtfps/<repo>.git D:\backup\<repo>.git   # 必须
pip install git-filter-repo
git filter-repo --path <dir> --invert-paths --force
git remote add origin https://github.com/xhtfps/<repo>.git
git push --force --all; git push --force --tags
```
本机 `github.com` 被 DNS 污染到 `57.155.223.240`（只有 `api.github.com` 直连可用），`clone --mirror` 与 `push --force` 都跑不了，**这一步只能由你在有网机器上执行**。重写后 `notes/offload.json` 里的 `base_commit` 链接会失效，需先导出 PDF 再重写。

## 6. 验收对照

| 标准 | 结果 |
| --- | --- |
| 超 200 MB 仓从 7 个降到 ≤ 2 个 | ✅ 2 个（228 / 219 MB），恰达线 |
| 全库 HEAD ≤ 1.2 GB | ❌ 1,728 MB，不 rewrite 不可达（见 §5） |
| 移出的文件都有去向 | ✅ 253 条 PDF 在 `notes/manuals.md`“已移出”段带 `base_commit` 直链；trim 类（Vivado/库/权重）记在本文 §1 提交号 |
| 每个瘦身仓 README 写明“大文件去哪了” | ⬜ 仅在 `notes` 与本文有台账，各仓自身 README 未补（下一步） |
| 不破坏历史 | ✅ 全程普通提交，旧 SHA 与旧 clone 均有效 |

## 7. 风险与已知副作用

- GitHub 端 `diskUsage` 不会立即下降，等 GC；以 `HEAD 体积` 为准。
- `smart_robot`、`electronics-competition` 的 README 仍按旧路径写复现步骤，clone 后会发现文件不在——需补“从哪下载”。
- `electronics-competition` 移走 StdPeriph 后，只依赖模板自带 `Libraries` 的工程仍可编译；若某工程直接引用 `STM32F4xx_DSP_StdPeriph_Lib_V1.9.0/`，需从 ST 官网补回。
- 本机 PowerShell `Invoke-RestMethod` 在该链路会随机 `Received an unexpected EOF`，批量操作统一走 `tools/gh_tool.py`。
