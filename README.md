# XHTFPS · 嵌入式 / AI 视觉项目库

个人工程总索引（GitHub 数据库入口）。全部仓库按“项目”归并，一个项目一个仓库；课程实验、基础模板不再单独开仓库，作为子目录并入对应项目库。

## 1. 项目库一览

**公开**

| 仓库 | 方向 | 硬件 / 平台 | 状态 |
| --- | --- | --- | --- |
| [stm32f4-projects](https://github.com/xhtfps/stm32f4-projects) | STM32F407 工程集 | 探索者 F407ZGT6 + Keil | 维护中 |
| [stm32h7-projects](https://github.com/xhtfps/stm32h7-projects) | STM32H743 工程集 | H743 + LTDC/AT070TN83 | 维护中 |
| [freertos-labs](https://github.com/xhtfps/freertos-labs) | FreeRTOS 实验 00–10 | F407 + Keil | 已完成 |
| [esp32-k230-ai](https://github.com/xhtfps/esp32-k230-ai) | ESP32-S3 + K230 边缘视觉 | ESP-IDF + CanMV | 维护中 |
| [STM32F407-LVGL-SSD1963](https://github.com/xhtfps/STM32F407-LVGL-SSD1963) | 机器人 + LVGL 屏 | F407 + SSD1963 + PS2 | 维护中 |
| [dl-pytorch-course](https://github.com/xhtfps/dl-pytorch-course) | 深度学习课程代码 | PyTorch 2.x | 已完成 |
| [RLC_dac_study_flash](https://github.com/xhtfps/RLC_dac_study_flash) | RLC/DAC/Flash 学习工程 | F407 + AD9959/ADF4351 | 维护中 |

**私有**（含第三方资料或未公开内容）

| 仓库 | 方向 | 备注 |
| --- | --- | --- |
| `electronics-competition` | 电赛校赛资料与工程 | 仪器仪表类、G 题、示波器、信号源 |
| `hardware-course-materials` | 硬件零基础课程 | Multisim + 封装库 + 课件 |
| `zynq-navigator-board` | ZYNQ 开发板资料索引 | 官方资料，版权归正点原子 |
| `nir-moisture-meter` | 近红外水分仪项目 | 固件 + 上位机 + 交付资料 |
| `smart_robot` | 智能机器人（语音/视觉） | Whisper + GPT-SoVITS + YOLO |
| `code` | 2025 数模 B 题代码 | Q1-Q4 学生成绩与焦虑分析 |

## 2. 仓库惯例

- **一项目一仓库**：同一块板卡的工程放同一仓库（如 F407 全部进 `stm32f4-projects`），不再按“每次实验一个仓库”拆分。
- **一个仓库一个 README**：必须写清环境、编译、烧录、目录、常见问题。已统一执行。
- **只存可版本化的东西**：源码、文档、小型资源入库；`.o/.d/.crf`、`Output/`、`*.uvguix.*`、`JLinkLog.txt`、固件镜像、视频、数据集、模型权重不入库。
- **排除清单**：每个归档仓库根目录的 `EXCLUDED_MANIFEST.csv` 记录被排除的文件路径、体积与原因。
- **公开/私有**：含第三方商业资料（开发板资料盘、课程课件）一律私有。

## 3. 归并记录

| 原仓库 | 去向 | 处理 |
| --- | --- | --- |
| `01_…` ～ `10_…`（10 个 FreeRTOS 实验仓库） | `freertos-labs` | 已逐一比对文件内容后并入，原仓库归档 |
| `freertos_project_template` | `freertos-labs/00_freertos_project_template` | 模板已并入，原仓库归档 |
| `STM32project` | `stm32f4-projects` | 同源旧版，仅 2 个源文件版本差异，原仓库归档 |
| `k230-esp32-vision-link` | `esp32-k230-ai` | 源码已全部包含，原仓库归档 |
| `dancing-robot-multimodal` | `esp32-k230-ai` | 仅框架文件，原仓库归档 |

## 4. 待办（已知缺陷）

1. 已归档仓库尚未删除，个人主页仍显示 15 个空壳仓库。
2. `code` 仓库名无信息量，仓库描述曾为 `System.Collections.Hashtable[…]`（脚本写入异常），已统一修正描述。
3. `STM32F407-LVGL-SSD1963` 仍含 `JLinkLog.txt`（1.4 MB）与多份 `*.uvguix.*`。
4. `electronics-competition` 存在 `15.3 APFFT…/15.3 APFFT…` 同名目录嵌套两层的历史拷贝。
5. `zynq-navigator-board` 有 `(1)` 重复文件，仓库体积 289 MB。
6. 部分仓库被误设为 Template（如 `RLC_dac_study_flash`），已修正。
7. 全库无统一的 LICENSE / Release / CI，建议按需补。

## 5. 命名约定

- 芯片/板卡类：`<芯片>-<主题>`，如 `stm32f4-projects`、`zynq-navigator-board`。
- 项目类：`<项目名>`，全小写加连字符，如 `nir-moisture-meter`。
- 不使用 `code`、`test`、`new`、`temp` 这类无信息量名称。
