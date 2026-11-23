# 大仓瘦身计划（SLIM-PLAN）

目标：把 7 个超 200 MB 的仓压到 200 MB 以下，全库 HEAD 体积从 **2,933 MB** 降到 **1.2 GB 以内**，同时保留每个文件的可追溯性（移出去的东西进 `notes` 手册索引或 Release）。

本文件只做计划与命令模板；**历史重写是不可逆操作**，执行前必须备份，且只能由本人在有网机器上跑。

## 1. 现状（按 HEAD 检出体积实测）

| 仓库 | HEAD | 其中 PDF | 主要占用 | 处置优先级 |
| --- | --- | --- | --- | --- |
| `zynq-navigator-board` | 480 MB | 296 MB（89 个） | `4_Source_Code` 132 MB、`2_文档教程` 91 MB、`7_芯片数据手册` 61 MB、`9_底板资料` 60 MB | P0 |
| `stm32f4-reference-materials` | 375 MB | 54 MB（16 个） | `14，LVGL学习资料` 59 MB、`freertos_project_template` 59 MB、`STM32F407ZGT6+SRAM` 58 MB | P1 |
| `stm32f407-board-materials` | 294 MB | 190 MB（133 个） | `7，硬件资料` 117 MB（含 133 个 PDF，大量 `(1)` 重复） | P0 |
| `smart_robot` | 291 MB | 0 | 模型权重、依赖包、录屏，无 PDF | P1 |
| `stm32f4-projects` | 250 MB | 31 MB（15 个） | `往年题目` 74 MB（参考资料 PDF + 旧工程） | P2 |
| `stm32-cubemx-labs` | 241 MB | 2 MB（1 个） | 10219 个文件，Hex/工程产物占大头，需先跑体检定位 | P2 |
| `electronics-competition` | 218 MB | 19 MB（15 个） | 历史拷贝嵌套 + 超长路径 | P2 |
| `shuweibei-cup-b2026` | 171 MB | 30 MB（69 个） | `B题代码` 70 MB、`论文+支撑材料` 37 MB | P3（未超线） |

## 2. 处置原则

1. **PDF 全部出仓**：芯片手册、板级原理图、教程 PDF 改登记到 `notes` 的 [`manuals.md`](https://github.com/xhtfps/notes/blob/main/manuals.md)，仓里只留链接。厂商版权资料本来也不适合反复分发。
2. **二进制与产物出仓**：`.hex/.bin/.zip/.rar/.7z/.iso/.mp4`、Vivado/ISE/Quartus 工程产物（`*.bit`、`*.hdf`、`project_*`、`*.dcp`）走 Release 或对象存储，README 写下载脚本。
3. **重复文件先去重**：`(1)`、`(2)` 后缀与同名副本先在同一仓内删掉（普通 commit 即可，不必重写历史），能省 20–40 MB 且零风险。
4. **源码不动**：`4_Source_Code` 里若是真源码就不删；只清 `*.bit`、`*.jou`、`*.log`、`*.str`、工程缓存。定删之前 `tools/slim-history.ps1 -Repo <仓>` 先看前 20 大文件。
5. **一次一仓**：重写历史会改所有 SHA，不要批量并行，验收一仓再下一仓。

## 3. 单仓执行步骤

```powershell
# 0) 备份（必须，重写不可逆）
git clone --mirror https://github.com/xhtfps/<repo>.git D:\backup\<repo>.git

# 1) 只读分析，看前 20 大文件与候选目录
pwsh ./tools/slim-history.ps1 -Repo <repo>

# 2) 确认路径后重写（示例：zynq 仓）
pwsh ./tools/slim-history.ps1 -Repo zynq-navigator-board `
    -Remove "7_芯片数据手册" `
    -Remove "2_文档教程/配套PDF" `
    -Apply
```

脚本内部做的是：`git clone --bare` → `git filter-repo --path <dir> --invert-paths` → 加回 origin → `git push --force --all` + `--tags`。

## 4. 每仓候选清单（先核对再删）

**zynq-navigator-board（P0，目标 −300 MB）**
- `7_芯片数据手册`（61 MB，纯 PDF）
- `2_文档教程` 下的 PDF 子目录（91 MB 里挑 PDF）
- `9_领航者ZYNQ底板V3.7版本…`（60 MB，多为原理图/装配图 PDF）
- `4_Source_Code` 里先删 `*.bit`、`*.dcp`、`*.hdf`、`*.jou`、`*.log`，不要动 `.v/.sv/.xdc`

**stm32f407-board-materials（P0，目标 −190 MB）**
- `7，硬件资料` 全目录（117 MB，133 个 PDF）。已用 blob SHA 比对过带 `(1)` 后缀的文件，**没有字节级重复**，只能整目录移出并登记 manuals.md，不能靠“删重复”省体积
- 根目录 `FreeRTOS开发指南_V1.12.pdf`（15.7 MB）
- `4，程序源码` 里的 `Objects/`、`Listings/`、`*.hex`

**stm32f4-reference-materials（P1，目标 −150 MB）**
- `14，LVGL学习资料`（59 MB，PDF + 视频）
- `freertos_project_template`（59 MB，与 `freertos-labs/00_…` 重复，删前先比对 SHA）
- `STM32F407ZGT6+SRAM`（58 MB，含 Altium 工程与 PDF）

**smart_robot（P1，目标 −150 MB）**
- 模型权重（`*.pth`、`*.onnx`、`*.bin`）移 Release，README 写 `tools/download-weights.ps1`
- 录屏与演示视频（`*.mp4`）移 Release 或直接删
- `site-packages`、`venv`、`node_modules` 一类依赖目录（若存在，必须删）

**stm32f4-projects（P2，目标 −100 MB）**
- `往年题目/超声波测距/参考资料`（20.6 MB 参考手册 + 若干原理图 PDF）
- `往年题目/AD7606模块资料-V3.2/原理图PDF`
- 其它 `往年题目/*/参考资料` 下的 PDF 与压缩包

**stm32-cubemx-labs（P2，先诊断）**
- 先跑 `tools/slim-history.ps1 -Repo stm32-cubemx-labs` 看前 20 大文件；241 MB 无 PDF，说明是 Hex/工程产物或`.rar` 安装包，按第 2 条原则处理

**electronics-competition（P2，顺带修路径）**
- 同名目录嵌套先扁平化（普通提交），再删 `*.zip`、`*.rar` 与重复 PDF
- 同时在 `.gitattributes` 落 `core.longpaths=true`

## 5. 验收标准

- `HEALTH.md` 的“超 200 MB 仓”从 7 个降到 ≤ 2 个（允许 `smart_robot`、`zynq-navigator-board` 因权重与源码体积保留）。
- 全库 HEAD 体积 ≤ 1.2 GB。
- `notes/manuals.md` 覆盖所有被移出的 PDF 条目（跑一次 `tools/build-notes.ps1` 后 PDF 数应显著下降，且每条都能在索引里找到去向）。
- 每个被瘦身的仓在 README 顶部有一行“大文件去哪了”的说明与 Release 链接。

## 6. 风险

- 重写后所有旧 clone 失效，需要重新 clone；如果还有别的机器在用这些仓，先同步。
- GitHub 端不会立即回收空间，`diskUsage` 要等 GC（通常几小时到一天），以 `HEALTH.md` 的 HEAD 体积为准。
- `filter-repo` 会删掉 `origin` 远程，脚本已处理；若手工执行记得 `git remote add origin`。
- 删错路径无法从 GitHub 恢复，只能靠第 0 步的 `--mirror` 备份。
