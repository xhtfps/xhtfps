# XHTFPS · 嵌入式 / AI 视觉项目库

个人工程总索引（GitHub 项目库入口）。全部仓库按“项目”归并，一个项目一个仓库；课程实验、基础模板不再单独开仓库，作为子目录并入对应项目库。统一格式见 [`REPO-STANDARD.md`](https://github.com/xhtfps/xhtfps/blob/main/REPO-STANDARD.md)。

## 1. 项目库一览

**公开（7）**

| 仓库 | 方向 | 硬件 / 平台 | 状态 |
| --- | --- | --- | --- |
| [stm32f4-projects](https://github.com/xhtfps/stm32f4-projects) | STM32F407 工程集 | 探索者 F407ZGT6 + Keil | 维护中 |
| [stm32h7-projects](https://github.com/xhtfps/stm32h7-projects) | STM32H743 工程集 | H743 + LTDC/AT070TN83 | 维护中 |
| [freertos-labs](https://github.com/xhtfps/freertos-labs) | FreeRTOS 实验 00–10 | F407 + Keil | 已完成 |
| [esp32-k230-ai](https://github.com/xhtfps/esp32-k230-ai) | ESP32-S3 + K230 边缘视觉 | ESP-IDF + CanMV | 维护中 |
| [STM32F407-LVGL-SSD1963](https://github.com/xhtfps/STM32F407-LVGL-SSD1963) | 六足机器人 + LVGL 屏 | F407 + SSD1963 + PS2 | 维护中 |
| [RLC_dac_study_flash](https://github.com/xhtfps/RLC_dac_study_flash) | RLC 阻抗测量仪 | F407: DAC 激励 + 双 ADC + FFT | 已完成 |
| [dl-pytorch-course](https://github.com/xhtfps/dl-pytorch-course) | 深度学习课程代码 | PyTorch 2.x | 已完成 |

**私有（7）**（含第三方资料或未公开内容）

| 仓库 | 方向 | 备注 |
| --- | --- | --- |
| `electronics-competition` | 电赛校赛资料与工程 | 仪器仪表类、G 题、示波器、信号源、超声波 |
| `hardware-course-materials` | 硬件零基础课程 | Multisim + 封装库 + 课件 |
| `zynq-navigator-board` | ZYNQ 开发板资料索引 | 官方资料，版权归正点原子 |
| `nir-moisture-meter` | 近红外水分仪项目 | 固件 + 上位机 + 交付资料 |
| `smart_robot` | 智能机器人（语音/视觉） | Whisper + GPT-SoVITS + YOLO |
| `math-modeling-2025` | 2025 数模 B 题代码 | Q1-Q4 AI 使用情况分析 |

## 2. 仓库惯例

- **一项目一仓库**：同一块板卡的工程放同一仓库（如 F407 全部进 `stm32f4-projects`），不再按“每次实验一个仓库”拆分。
- **一仓库一 README**：必须写清环境、编译、烧录、目录、常见问题（六段结构见 REPO-STANDARD）。
- **每个仓库都有 `LICENSE`**：公开工程 MIT；含第三方资料的仓库写“保留所有权利 + 第三方说明”。
- **只存可版本化的东西**：源码、文档、小型资源入库；`.o/.d/.crf`、`Output/`、`*.uvguix.*`、`JLinkLog.txt`、固件镜像、视频、数据集、模型权重不入库。

## 3. 归并记录

| 原仓库 | 去向 | 处理 |
| --- | --- | --- |
| `01_…` ～ `10_…`（10 个 FreeRTOS 实验） | `freertos-labs` | 按文件内容逐项比对后并入，原仓库归档 |
| `freertos_project_template` | `freertos-labs/00_freertos_project_template` | 模板源码已完整并入 |
| `STM32project` | `stm32f4-projects` | 同源旧版，仅 2 个源文件版本差异 |
| `k230-esp32-vision-link` | `esp32-k230-ai` | 源码已全部包含 |
| `dancing-robot-multimodal` | `esp32-k230-ai` | 仅框架文件 |

## 4. 已完成的标准化工件

- 14 个活跃仓库已统一补齐 `LICENSE`、`.gitattributes`、`topics`、中文描述。
- `code` 已改名为 `math-modeling-2025`；误设的 Template 标记已清除。
- 已删除 `JLinkLog.txt`、`*.uvguix.*`、`keil_build.log` 与 zynq 的 `(1)` 重复文件。

## 5. 剩余待办

1. 14 个归档空壳尚未删除（GitHub 可恢复期内删除，命令见总账文档）。
2. 体积偏大：`zynq-navigator-board` 289 MB、`smart_robot` 274 MB、`dl-pytorch-course` 196 MB。
3. `electronics-competition` 同名目录嵌套两层，长路径在 Windows 下会导致 clone 失败。
4. `esp32-k230-ai` 的 `EXCLUDED_MANIFEST.csv` 4.4 MB，建议只留摘要。

## 6. 命名约定

见 [`REPO-STANDARD.md`](https://github.com/xhtfps/xhtfps/blob/main/REPO-STANDARD.md)：芯片类 `<芯片>-<主题>`，项目类全小写连字符，禁用 `code`/`test`/`new`/`temp`。
