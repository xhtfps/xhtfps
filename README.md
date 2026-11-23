# XHTFPS · 嵌入式 / AI 视觉项目库

个人工程总索引（GitHub 项目库入口）。全部仓库按“项目”归并：一个项目一个仓库，课程实验、基础模板作为子目录并入所属项目库，不再单独开仓库。统一格式与体积红线见 [`REPO-STANDARD.md`](https://github.com/xhtfps/xhtfps/blob/main/REPO-STANDARD.md)，全库体检用 [`tools/repo-audit.ps1`](https://github.com/xhtfps/xhtfps/blob/main/tools/repo-audit.ps1)，机器可读索引是 [`catalog.json`](https://github.com/xhtfps/xhtfps/blob/main/catalog.json)。

<!-- CATALOG:START -->
## 1. 仓库地图（22 个内容仓库 + 本索引）

> 本节由 `tools/build-index.ps1` 生成，请勿手改；新增或改动仓库后重跑脚本。公开 11 个 / 私有 11 个。

### 1.1 板卡工程集（6）

| 仓库 | 定位 | 可见性 | 芯片 / 板卡 | 技术栈 | 体积 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| [esp32-k230-ai](https://github.com/xhtfps/esp32-k230-ai) | ESP32-S3 与 K230 双板协作的边缘 AI 视觉工程（双板联调、机器人集成、语音交互） | 公开 | ESP32-S3 + K230 / 自制双板 | ESP-IDF · CanMV MicroPython | 45 MB | 维护中 |
| [freertos-labs](https://github.com/xhtfps/freertos-labs) | STM32F407 + FreeRTOS 课程实验全集（00 工程模板 + 01-10 实验） | 公开 | STM32F407ZGT6 / 正点原子 探索者 V3 | Keil MDK · FreeRTOS 10 | 17 MB | 已完成 |
| [stm32-cubemx-labs](https://github.com/xhtfps/stm32-cubemx-labs) | STM32 CubeMX HAL 工程集（LED/KEY/TIM/USART/ADC/FreeRTOS）与标准外设库工程模板 | 公开 | STM32（型号见各工程） / 无固定板卡 | CubeMX HAL · 标准外设库 | 242 MB | 新建 |
| [stm32f4-projects](https://github.com/xhtfps/stm32f4-projects) | STM32F407 工程集：基地调试程序（5 个子工程）、工程模板、往年与电赛题目 | 公开 | STM32F407ZGT6 / 正点原子 探索者 V3 | Keil MDK · HAL/标准库 | 140 MB | 维护中 |
| [stm32h7-projects](https://github.com/xhtfps/stm32h7-projects) | STM32H743 工程集：裸机、FreeRTOS、LVGL 模板，LTDC 液晶驱动，谐波测量结项 | 公开 | STM32H743 / AT070TN83 7 寸屏 | Keil MDK · HAL · FreeRTOS · LVGL | 27 MB | 维护中 |
| [zynq-fpga-projects](https://github.com/xhtfps/zynq-fpga-projects) | ZYNQ-7020 FPGA 基础工程集：呼吸灯、按键、数码管、RAM/FIFO/时钟 IP 核 | 公开 | ZYNQ-7020 / 正点原子 领航者 | Vivado · Verilog/VHDL | 75 MB | 维护中 |

### 1.2 具体项目（7）

| 仓库 | 定位 | 可见性 | 芯片 / 板卡 | 技术栈 | 体积 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| [dance-robot-esp32](https://github.com/xhtfps/dance-robot-esp32) | ESP32 舞蹈机器人：主控固件、视觉模块、机械固件与比赛文档 | 公开 | ESP32 / 自制舞蹈机器人整机 | ESP-IDF · 舵机控制 | 54 MB | 维护中 |
| [fad-vision-research](https://github.com/xhtfps/fad-vision-research) | 跨域目标检测研究：ACDC 基准实验、FAD 频域自适应检测、AFPN 参考实现与评估脚本 | 私有 | GPU 训练环境 / ACDC 数据集 | PyTorch · ACDC/FAD/AFPN | 99 MB | 进行中 |
| [lissajous-figure-device](https://github.com/xhtfps/lissajous-figure-device) | 2026 电赛 F 题：基于 STM32F407 的李萨如图形显示控制装置 | 公开 | STM32F407 / 自建装置（DAC 输出） | Keil MDK · DAC/DMA | 15 MB | 维护中 |
| [nir-moisture-meter](https://github.com/xhtfps/nir-moisture-meter) | 在线式双波长近红外水分仪：STM32 固件 + 上位机 + Modbus 协议 + 硬件/EDA 交付资料 | 私有 | STM32 / 自建近红外水分仪 | Keil MDK · Modbus · 上位机 | 25 MB | 维护中 |
| [RLC_dac_study_flash](https://github.com/xhtfps/RLC_dac_study_flash) | RLC 阻抗测量仪（结项）：F407 DAC 激励 + 双 ADC 采样 + FFT 解算，附 AD9959/ADF4351/AD8370 驱动与 CMSIS-DSP | 公开 | STM32F407ZGT6 / 基地板 | Keil MDK · HAL · CMSIS-DSP | 17 MB | 已完成 |
| [smart_robot](https://github.com/xhtfps/smart_robot) | 智能机器人（软件侧）：语音交互 + Whisper 识别 + GPT-SoVITS 合成 + OpenCV/YOLO 视觉 + URDF 模型 | 私有 | PC（外接麦克风/摄像头） / — | Python · Whisper · GPT-SoVITS · YOLO | 274 MB | 维护中 |
| [STM32F407-LVGL-SSD1963](https://github.com/xhtfps/STM32F407-LVGL-SSD1963) | 六足平衡机器人（STM32F407 + LVGL + SSD1963 + PS2 手柄 + 触摸屏 UI） | 私有 | STM32F407ZGT6 / 六足机器人自建板 | Keil MDK · LVGL · SSD1963 | 57 MB | 维护中 |

### 1.3 竞赛与课程（5）

| 仓库 | 定位 | 可见性 | 芯片 / 板卡 | 技术栈 | 体积 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| [dl-pytorch-course](https://github.com/xhtfps/dl-pytorch-course) | PyTorch 深度学习课程：CNN/LSTM 代码、数据与课堂笔记 | 公开 | PC/GPU / — | PyTorch 2.x · CNN/LSTM | 27 MB | 已完成 |
| [electronics-competition](https://github.com/xhtfps/electronics-competition) | 电赛/校赛项目与资料库：示波器、信号发生器、超声波测距、2025 G 题（含第三方资料，私有） | 私有 | STM32F407 等 / 历年赛题平台 | Keil MDK · STM32 | 83 MB | 维护中 |
| [math-modeling-2025](https://github.com/xhtfps/math-modeling-2025) | 2025 数模 B 题代码：学生成绩与焦虑相关问题 Q1-Q4（Python） | 私有 | PC / — | Python · 数模求解 | 3 MB | 已完成 |
| [opencv-basics](https://github.com/xhtfps/opencv-basics) | OpenCV + Python 图像处理入门代码与示例 | 公开 | PC / — | Python · OpenCV | 2 MB | 已完成 |
| [shuweibei-cup-b2026](https://github.com/xhtfps/shuweibei-cup-b2026) | 2026 数维杯国际赛 B 题：四问求解代码、模型推导报告、论文多版修改稿与支撑材料 | 私有 | PC / — | Python · 数模求解 | 172 MB | 进行中 |

### 1.4 资料库（4）

| 仓库 | 定位 | 可见性 | 芯片 / 板卡 | 技术栈 | 体积 | 状态 |
| --- | --- | --- | --- | --- | --- | --- |
| [hardware-course-materials](https://github.com/xhtfps/hardware-course-materials) | 硬件零基础课程资料：课件、Multisim 仿真工程、OrCAD/Altium 封装库与辅助表格 | 私有 | — / 硬件零基础课程 | Multisim · OrCAD/Altium（只读） | 14 MB | 只读归档 |
| [stm32f4-reference-materials](https://github.com/xhtfps/stm32f4-reference-materials) | STM32F407 参考资料与例程：基地板调试程序、AD9959、LVGL、FreeRTOS 模板、示波器工程 | 私有 | STM32F407 / 本机资料盘归档 | 例程/手册（只读） | 424 MB | 只读归档 |
| [stm32f407-board-materials](https://github.com/xhtfps/stm32f407-board-materials) | 正点原子探索者 V3（STM32F407ZGT6）开发板资料：文档、原理图、例程与硬件资料 | 私有 | STM32F407ZGT6 / 正点原子 探索者 V3 | 厂商文档/原理图/例程（只读） | 365 MB | 只读归档 |
| [zynq-navigator-board](https://github.com/xhtfps/zynq-navigator-board) | 正点原子领航者 ZYNQ 开发板资料索引：教程、原理图、引脚表、FPGA/Vitis/Linux 源码（第三方资料） | 私有 | ZYNQ-7020 / 正点原子 领航者 | 厂商文档/源码（只读） | 439 MB | 只读归档 |

> 体积 = HEAD 检出文件的真实体积（`git/trees?recursive=1` 求和）；`diskUsage`（含历史）仅作回退。分类、芯片、状态的权威口径在 `tools/catalog-rules.json`。

<!-- CATALOG:END -->

## 2. 容易混的仓库，边界在哪

| 容易混 | 区分口径 |
| --- | --- |
| `stm32f4-projects` / `stm32f4-reference-materials` | 前者是整理后的工程集（只留源码、按工程组织），后者是本机资料盘**原样备份**（含例程、手册、旧工程，不做二次整理） |
| `stm32f4-projects` / `stm32f407-board-materials` | 前者是“我自己写的工程”，后者是“厂商原始资料与手册” |
| `stm32f4-projects` / `electronics-competition` | 前者按**板卡**归口（模板、基地调试、历年题目），后者按**赛事**归口（历次竞赛的完整资料） |
| `lissajous-figure-device` / `electronics-competition` | 前者是 2026 F 题单独立项的项目仓，后者是历年赛题资料合集 |
| `zynq-fpga-projects` / `zynq-navigator-board` | 前者是“我写的 FPGA 工程”，后者是“厂商板卡资料” |
| `esp32-k230-ai` / `dance-robot-esp32` | 前者是双板协议与联调（K230 侧 + ESP32 侧），后者是舞蹈机器人整机；整机代码已从前者移除，只在后者维护 |
| `RLC_dac_study_flash` / `electronics-competition` | 前者是单一结项仪器，后者是资料合集；信号源、示波器内容不在两处重复存放 |
| `smart_robot` / `dance-robot-esp32` / `STM32F407-LVGL-SSD1963` | 三个机器人仓：软件侧语音视觉（PC）/ ESP32 舞蹈机器人整机 / F407 六足硬件 |
| `freertos-labs` / `stm32f4-projects` | 前者按实验编号组织，后者按工程组织；FreeRTOS 模板只在 `freertos-labs/00` 维护一份 |
| `stm32f4-projects` / `stm32-cubemx-labs` | 前者是 F407 单板工程集，后者是跨芯片的 CubeMX 学习工程与标准库模板 |

## 3. 仓库惯例

- **一项目一仓库**：同一块板卡的工程放同一仓库，不再按“每次实验一个仓库”拆分。
- **一仓库一 README**：五段结构（目录 / 环境 / 快速开始与关键实现 / 常见问题 / 维护说明）。
- **每个仓库都有 `LICENSE`、`.gitignore`、`.gitattributes`、≥ 3 个 topics**。
- **只存可版本化的东西**：源码、文档、小型资源入库；编译产物、固件镜像、数据集、模型权重、安装包都不入库。
- **排除清单只留摘要**：每个仓库一个 `EXCLUDED_FILES.md`，不存逐文件 CSV。
- **索引自动生成**：仓库地图只维护 `catalog.json` 与 `tools/catalog-rules.json`，README 表格交给脚本重写。

## 4. 归并记录（已完成）

| 原仓库 / 原目录 | 去向 | 核对方式 | 处理 |
| --- | --- | --- | --- |
| `01_…` ～ `10_…`（10 个 FreeRTOS 实验） | `freertos-labs/01`–`10` | 逐文件 SHA 比对：05–10 完全一致；01–04 差异仅为 `Output/` 编译产物 | 仓库已删除 |
| `freertos_project_template` | `freertos-labs/00_freertos_project_template` | 源码一致，差异仅 `uvoptx/uvguix/JLinkLog` 等 Keil 用户配置与日志 | 仓库已删除 |
| `STM32project` | `stm32f4-projects/基地调试程序` | 86 个用户代码文件均有同名演进版；旧工程与参考资料完整保留在 `往年题目/超声波测距` | 仓库已删除 |
| `k230-esp32-vision-link` | `esp32-k230-ai/K230+ESP32/ESP32` | 224 个同名文件中 220 个在新仓库，`components/BSP`、`docs`、`tests` 齐全 | 仓库已删除 |
| `dancing-robot-multimodal` | 无需并入 | 仅 9 个 ESP-IDF 骨架文件，无源码 | 仓库已删除 |
| `esp32-k230-ai/robot/`（整机副本） | `dance-robot-esp32` | 9 个文件的同名对应全部存在，且完整工程含 `eyes`/`jx_firm`/答辩材料 | 子目录已移除，README 留跳转 |

**28 → 14 → 21 → 23（22 内容 + 1 索引）**：14 个归档空壳全部删除；随后本机资料盘归档与新项目拆仓补入 7 个仓库（5 个新项目/课程仓 + 2 个资料库仓）。当前为 **22 个内容仓库 + 本索引**，新增的 `stm32-cubemx-labs`、`shuweibei-cup-b2026` 已由 `catalog.json` 自动收录，不再依赖手改表格。删除前已记录各仓库 HEAD SHA，90 天内可通过 GitHub Support 恢复，清单见 `GitHub仓库合并记录-2026-11-23.md`。

## 5. 已完成的整理

**第一轮（归并与文档）**：28 → 14，逐文件内容比对后合并；仓库重写 README；修正 11 处乱码描述。

**第二轮（格式统一）**：补齐 `LICENSE`/`.gitattributes`/`.gitignore`/topics；清理垃圾生成物（JLinkLog、uvguix、uvoptx、`(1)` 重复文件）；4 个结项仓库发 Release；`code` 改名 `math-modeling-2025`。

**第三轮（体积与清单）**：

- `dl-pytorch-course`：删除 CIFAR-10 原始批次（186 MB），改为下载说明。
- `STM32F407-LVGL-SSD1963`：删除未启用的 LVGL `demos/`（56.6 MB）。
- 6 个仓库的逐文件 `EXCLUDED_MANIFEST.csv`（合计 **8.2 MB**）全部改为 `EXCLUDED_FILES.md` 摘要。
- `REPO-STANDARD.md` 补上体积红线、数据集规则、目录深度上限。
- 新增 `tools/repo-audit.ps1`（全库合规体检）与 `tools/slim-history.ps1`（历史重写瘦身）。

**第四轮（索引自动化）**：

- 新增 `tools/build-index.ps1`：扫描全部仓库，读取 README 环境段与关键词，生成 `catalog.json`，并重写本文 §1 的四张表；`-RenderOnly` 可离线重排。
- 新增 `tools/catalog-rules.json`：分类、芯片、板卡、状态的人工口径，优先于自动识别结果。
- 修正索引落后问题：`stm32-cubemx-labs`、`shuweibei-cup-b2026` 纳入仓库地图。
- 修复 `stm32f4-projects` README 的 `EXCLUDED_MANIFEST.csv` 死链，删除仓库内 1.4 MB 的芯片手册 PDF。
- `stm32-cubemx-labs` 的 10 MB 逐文件清单 `EXCLUDED_MANIFEST.csv` 改为 `EXCLUDED_FILES.md` 摘要。

## 6. 仍然存在的缺陷

| # | 问题 | 现状 | 建议 |
| --- | --- | --- | --- |
| 1 | 三个资料库体积偏大：`zynq-navigator-board` 439 MB、`stm32f4-reference-materials` 424 MB、`stm32f407-board-materials` 365 MB | 几乎全是厂商 PDF、视频、安装包 | 用 `tools/slim-history.ps1` 移出大文件后重写历史 |
| 2 | 两个 F407 资料库各存一份 `STM32F407ZGT6.pdf`、`STM32F4xx参考手册`；`stm32f407-board-materials` 另有 8 对 `(1)` 重复 PDF | 下载重复与逐文件清单 | 每个手册只留一份；清单改 `EXCLUDED_FILES.md` 摘要 |
| 3 | `smart_robot` 274 MB | 模型权重与依赖占大头 | 权重走 Release / LFS，README 写下载脚本 |
| 4 | `stm32f4-projects` 140 MB | 含厂商手册与重复参考程序 | 同上，先跑体检再定移除路径 |
| 5 | `electronics-competition` 同名目录嵌套、超长路径 | 历史拷贝，Windows 默认 clone 会失败 | `.gitattributes` 已注明 `core.longpaths`；彻底修需重排目录 |
| 6 | 无 CI | 嵌入式工程 CI 成本高，只做静态体检 | 暂以本地手动跑 `tools/repo-audit.ps1` |
| 7 | 分支保护未开 | 单人仓库开了会阻塞自己 push | 有意不开启，靠提交习惯约束 |
| 8 | topics 词表不统一 | 多数仓库只有 `embedded` 之类的泛标签 | 待建 `TOPICS.md` 词表后批量补齐 |

## 7. 命名约定

见 [`REPO-STANDARD.md`](https://github.com/xhtfps/xhtfps/blob/main/REPO-STANDARD.md)：芯片类 `<芯片>-<主题>`，项目类全小写连字符，禁用 `code`/`test`/`new`/`temp`。

## 8. 索引维护

```powershell
# 全量：拉取账号下全部仓库（需 gh auth login 或 $env:GITHUB_TOKEN）
pwsh -File .\tools\build-index.ps1

# 离线：只按 catalog.json 重排 README 表格
pwsh -File .\tools\build-index.ps1 -RenderOnly

# 体检 + 索引一起跑
pwsh -File .\tools\repo-audit.ps1 -WriteReport
```

新增仓库时只改 `tools/catalog-rules.json` 的分类口径，再重跑脚本；不要手改 §1 的表格。