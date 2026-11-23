# topics 词表（统一口径）

GitHub topics 的唯一合法词表。`tools/set-topics.ps1` 按本表给每个仓库算标签，**不在表内的标签会被剔除**（要加新标签先改这里）。

## 1. 结构与用途

| 标签 | 用于 | 例 |
| --- | --- | --- |
| `index` | 总索引仓 | xhtfps |
| `project-collection` | 多工程合集（板卡工程集） | stm32f4-projects、freertos-labs |
| `project` | 单个完整项目 | smart_robot、lissajous-figure-device |
| `course` | 课程/教程类 | dl-pytorch-course、opencv-basics |
| `competition` | 竞赛作品（含论文与代码） | electronics-competition、shuweibei-cup-b2026 |
| `reference` | 资料/手册库 | zynq-navigator-board、stm32f4-reference-materials |
| `driver-library` | 驱动库 | bsp-libs |
| `knowledge-base` | 知识库 | notes |

## 2. 芯片与平台

| 标签 | 含义 |
| --- | --- |
| `stm32f4` / `stm32h7` / `gd32` | STM32 F4、H7 系列，GD32 替代 |
| `esp32` / `esp32s3` | ESP32 系列 |
| `zynq` | Xilinx Zynq-7000 |
| `k230` | 嘉楠 K230 |
| `imx6ull` | NXP i.MX6ULL |

## 3. 工具链与框架

| 标签 | 含义 |
| --- | --- |
| `keil` | Keil MDK 工程 |
| `cubemx` | STM32CubeMX 生成工程 |
| `freertos` | FreeRTOS |
| `lvgl` | LVGL 图形库 |
| `espidf` | ESP-IDF |
| `canmv` | CanMV / MicroPython |
| `pytorch` | PyTorch 训练或推理 |
| `opencv` | OpenCV 视觉处理 |

## 4. 领域

`dds`、`adc`、`imu`、`motor-control`、`power-electronics`、`signal-processing`、`computer-vision`、`deep-learning`、`yolo`、`speech`、`robot`、`dataset`、`math-modeling`

## 5. 外设型号

小写型号本身即标签：`ad9959`、`ads1256`、`mpu6050`、`adf4351`、`ssd1963`、`pga2310`、`si5351`、`ds18b20`、`tmp275`、`dac8562`。
外设标签最多取 3 个（按 `catalog.json` 的 `peripherals` 顺序），避免标签噪声。

## 6. 组合规则

- 每仓 3–8 个，顺序固定：**结构 → 芯片 → 工具链 → 领域 → 外设**。GitHub 不显示顺序，但便于脚本比对。
- 泛标签 `embedded`、`electronics`、`mcu` 只在没有更具体标签时兜底，不允许单独存在。
- 大小写一律小写 ASCII，不用空格与下划线（GitHub 会把空格转成 `-`，不如自己控制）。

## 7. 维护

```powershell
pwsh ./tools/set-topics.ps1 -DryRun   # 只打印将要写入的标签
pwsh ./tools/set-topics.ps1           # 真正写（需要 repo 权限 token）
```

脚本以 `catalog.json` 为输入，所以先跑 `tools/build-index.ps1`；新增仓库若没进 `catalog-rules.json`，它的标签只能从名称与 README 猜，记得先补规则。
