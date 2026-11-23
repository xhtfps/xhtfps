# XHTFPS · 嵌入式 / AI 视觉项目库

个人工程总索引（GitHub 项目库入口）。全部仓库按“项目”归并，一个项目一个仓库；课程实验、基础模板不再单独开仓库，作为子目录并入对应项目库。统一格式与体积红线见 [`REPO-STANDARD.md`](https://github.com/xhtfps/xhtfps/blob/main/REPO-STANDARD.md)，全库体检用 [`tools/repo-audit.ps1`](https://github.com/xhtfps/xhtfps/blob/main/tools/repo-audit.ps1)。

## 1. 项目库一览（14）

**公开（7）**

| 仓库 | 方向 | 内容体积 | 状态 |
| --- | --- | --- | --- |
| [stm32f4-projects](https://github.com/xhtfps/stm32f4-projects) | STM32F407 工程集 | 140 MB | 维护中 |
| [stm32h7-projects](https://github.com/xhtfps/stm32h7-projects) | STM32H743 工程集 | 27 MB | 维护中 |
| [freertos-labs](https://github.com/xhtfps/freertos-labs) | FreeRTOS 实验 00–10 | 17 MB | 已完成 |
| [esp32-k230-ai](https://github.com/xhtfps/esp32-k230-ai) | ESP32-S3 + K230 边缘视觉 | 45 MB | 维护中 |
| [STM32F407-LVGL-SSD1963](https://github.com/xhtfps/STM32F407-LVGL-SSD1963) | 六足机器人 + LVGL 屏 | 57 MB | 维护中 |
| [RLC_dac_study_flash](https://github.com/xhtfps/RLC_dac_study_flash) | RLC 阻抗测量仪 | 17 MB | 已完成 |
| [dl-pytorch-course](https://github.com/xhtfps/dl-pytorch-course) | 深度学习课程代码 | 27 MB | 已完成 |

**私有（7）**（含第三方资料或未公开内容）

| 仓库 | 方向 | 内容体积 | 状态 |
| --- | --- | --- | --- |
| [electronics-competition](https://github.com/xhtfps/electronics-competition) | 电赛资料与工程 | 83 MB | 维护中 |
| [zynq-navigator-board](https://github.com/xhtfps/zynq-navigator-board) | ZYNQ 开发板资料索引 | 439 MB | 维护中 |
| [smart_robot](https://github.com/xhtfps/smart_robot) | 智能机器人（语音/视觉） | 274 MB | 维护中 |
| [nir-moisture-meter](https://github.com/xhtfps/nir-moisture-meter) | 近红外水分仪 | 25 MB | 维护中 |
| [hardware-course-materials](https://github.com/xhtfps/hardware-course-materials) | 硬件零基础课程 | 14 MB | 已完成 |
| [math-modeling-2025](https://github.com/xhtfps/math-modeling-2025) | 2025 数模 B 题代码 | 3 MB | 已完成 |

> 内容体积 = 当前 HEAD 去重后的真实文件体积；GitHub 页面上的“体积”包含历史提交，需重写历史或服务端 GC 后才会下降。

## 2. 仓库惯例

- **一项目一仓库**：同一块板卡的工程放同一仓库，不再按“每次实验一个仓库”拆分。
- **一仓库一 README**：五段结构（目录 / 环境 / 快速开始与关键实现 / 常见问题 / 维护说明）。
- **每个仓库都有 `LICENSE`、`.gitignore`、`.gitattributes`、≥ 3 个 topics**。
- **只存可版本化的东西**：源码、文档、小型资源入库；编译产物、固件镜像、数据集、模型权重、安装包都不入库。
- **排除清单只留摘要**：每个仓库一个 `EXCLUDED_FILES.md`，不存逐文件 CSV。

## 3. 归并记录

| 原仓库 | 去向 | 处理 |
| --- | --- | --- |
| `01_…` ～ `10_…`（10 个 FreeRTOS 实验） | `freertos-labs` | 按 bl崐哈希逐文件比对后并入 |
| `freertos_project_template` | `freertos-labs/00_freertos_project_template` | 模板 438 个文件完整并入 |
| `STM32project` | `stm32f4-projects` | 同源旧版，仅 2 个源文件版本差异 |
| `k230-esp32-vision-link` | `esp32-k230-ai` | 源码已全部包含 |
| `dancing-robot-multimodal` | `esp32-k230-ai` | 仅框架文件 |

上表 14 个原仓库均已归档（Archive），文件已确认并入目标库，待删除（需 `delete_repo` 权限，见第 6 节）。

## 4. 已完成的三轮整理

**第一轮（归并与文档）**：28 → 14，逐文件内容比对后合并；14 个仓库重写 README；修正 11 处乱码描述。

**第二轮（格式统一）**：补齐 `LICENSE`/`.gitattributes`/`.gitignore`/topics；清理垃圾生成物（JLinkLog、uvguix、uvoptx、`(1)` 重复文件）；4 个结项仓库发 Release；`code` 改名 `math-modeling-2025`。

**第三轮（体积与清单）**：

- `dl-pytorch-course`：删除 CIFAR-10 原始批次（186 MB），改为下载说明。
- `STM32F407-LVGL-SSD1963`：删除未启用的 LVGL `demos/`（56.6 MB）。
- 6 个仓库的逐文件 `EXCLUDED_MANIFEST.csv`（合计 **8.2 MB**）全部改为 `EXCLUDED_FILES.md` 摘要。
- `REPO-STANDARD.md` 补上体积红线、数据集规则、目录深度上限。
- 新增 `tools/repo-audit.ps1`（全库合规体检）与 `tools/slim-history.ps1`（历史重写瘦身）。

## 5. 仍然存在的缺陷

| # | 问题 | 现状 | 建议 |
| --- | --- | --- | --- |
| 1 | 14 个归档空壳未删除 | 文件已并入，仓库仍占列表 | 需一次 `delete_repo` 授权（第 6 节命令） |
| 2 | `zynq-navigator-board` 439 MB、`smart_robot` 274 MB | 几乎全是厂商 PDF / 教程视频 / 安装包 | 用 `tools/slim-history.ps1` 移出大文件后重写历史 |
| 3 | `stm32f4-projects` 140 MB | 含厂商手册与重复参考程序 | 同上，先跑体检再定移除路径 |
| 4 | `electronics-competition` 同名目录嵌套、超长路径 | 历史拷贝，Windows 默认 clone 会失败 | 已在仓库 `.gitattributes` 注明 `core.longpaths`；彻底修需重排目录 |
| 5 | `smart_robot` 大文件依赖（LFS/手工下载） | 未校验完整性 | README 已写依赖清单，后续加下载脚本 |
| 6 | 无 CI | 嵌入式工程 CI 成本高，只做静态体检 | 本地/手动跑 `tools/repo-audit.ps1` |
| 7 | 分支保护未开 | 单人仓库开了会阻塞自己 push | 有意不开启，靠提交习惯约束 |

## 6. 删除归档仓库（需授权一次）

`gh repo delete` 需要 token 带 `delete_repo` 权限。先刷新授权：

```powershell
gh auth refresh -h github.com -s delete_repo
```

浏览器里输一次性码并点 Authorize，然后执行：

```powershell
$gone = @('01_task_create_delete_dynamic','02_task_create_delete_static','03_task_suspend_resume',
  '04_interrupt_management','05_list_and_item_insert_delete','06_Time-Slice-Scheduling-Experiment',
  '07_Task-Status-Query','08_Task-Runtime-Statistics-API-Functions','09_Delay-Function-Demonstration-Experiment',
  '10_Queue_Operations','STM32project','freertos_project_template',
  'k230-esp32-vision-link','dancing-robot-multimodal')
foreach($r in $gone){ gh repo delete "xhtfps/$r" --yes }
```

## 7. 命名约定

见 [`REPO-STANDARD.md`](https://github.com/xhtfps/xhtfps/blob/main/REPO-STANDARD.md)：芯片类 `<芯片>-<主题>`，项目类全小写连字符，禁用 `code`/`test`/`new`/`temp`。

