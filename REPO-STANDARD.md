# 仓库格式规范（REPO-STANDARD）

本账号下所有仓库必须满足以下格式。新建仓库直接按此执行，旧仓库逐步对齐。

## 1. 命名

| 类型 | 规则 | 示例 |
| --- | --- | --- |
| 芯片/板卡工程集 | `<芯片或板卡>-<主题>` | `stm32f4-projects`、`zynq-navigator-board` |
| 具体项目 | `<项目名>`，小写 + 连字符 | `nir-moisture-meter`、`smart_robot` |
| 课程/竞赛 | `<主题>-<年份或阶段>` | `dl-pytorch-course`、`math-modeling-2025` |

禁用：`code`、`test`、`new`、`temp`、`untitled`。

## 2. 每个仓库必须有的文件

| 文件 | 作用 | 要求 |
| --- | --- | --- |
| `README.md` | 唯一入口文档 | 必须含下方五段 |
| `LICENSE` | 版权声明 | 公开工程用 MIT；含第三方资料用“保留所有权利 + 第三方说明” |
| `.gitignore` | 阻止生成物入库 | 至少覆盖 `Output/`、`*.uvguix.*`、`JLinkLog.txt`、`__pycache__/` |
| `.gitattributes` | 行尾与二进制判定 | `* text=auto eol=lf`，大文件标 `binary` |
| `CONTRIBUTING.md` | 贡献指南 | 报 Issue / 提 PR 的流程、代码风格、不入库清单 |
| `SECURITY.md` | 安全策略 | 报告通道、响应时限、第三方组件不在范围内 |
| `.github/ISSUE_TEMPLATE/` | Issue 模板 | `bug_report.yml`、`feature_request.yml`、`config.yml`（禁空白 Issue） |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR 模板 | 改动内容、动机、验证方式、自查清单 |

可选：`EXCLUDED_FILES.md`（排除清单**摘要**）。体积超过 50 MB 的仓库必须有。

### 2.1 排除清单位规则

- 只写摘要（条目数、总体积、主要排除原因分布），不超过 2 KB。
- **禁止**把逐文件清单 `EXCLUDED_MANIFEST.csv` 入库：一个清单自己就能有 0.1～4.4 MB，既占体积又难读。
- 需要逐文件明细时放本地，不进 Git。

### 2.2 体积红线

| 项 | 上限 | 处理 |
| --- | --- | --- |
| 单个仓库（GitHub 上的体积） | 50 MB | 超出先查大文件、删可重新生成的内容 |
| 单个文件 | 5 MB | 超出放 Release 附件或外部网盘 |
| 单个数据集/模型权重 | 0 MB | 一律不入库，写下载脚本或说明 |

下列内容**一律不入库**，即使体积不大：训练权重（`*.pth/*.pt/*.ckpt/*.onnx`）、公开数据集原始批次、固件镜像（`*.hex/*.bin`，走 Release）、安装包（`*.zip/*.rar/*.exe/*.msi`）、厂商参考手册 PDF（放本地资料盘）、Vivado 中间产物（`*.dcp`、`sim_1/`、`.jobs/`）。

已胖起来的历史仓库，用 [`tools/slim-history.ps1`](tools/slim-history.ps1) 重写历史瘦身（会改 SHA，单人仓库才用）。

## 3. README 五段结构

```md
# 项目名（一句话定位）

（2-3 句：这是什么、解决什么问题、当前状态）

## 1. 目录一览
## 2. 环境（板卡 / MCU / IDE / 调试器 / 串口 / Python 依赖）
## 3. 快速开始与关键实现（编号步骤 + 关键参数、易错点）
## 4. 常见问题（每条：现象 → 原因 → 处理）
## 5. 维护说明（排除规则、合并去向、第三方版权、LFS 说明）
```

五段顺序不可调；缺段视为不合规。

### 3.1 五段之外：外观层（成熟项目标配）

五段前面加「头部块」，五段后面加「尾块」，中间五段原样保留。头部与尾部都不参与编号，避免打乱 §1–§5。

```md
<div align="center">
  <h1>项目名</h1>
  <p><b>一句话定位（能单独转发的句子）</b></p>
  <p>徽章：平台 / 工具链 / 许可证 / 最近提交</p>
  <p>3–4 个锚点链接：快速开始 · 常见问题 · 全部仓库索引</p>
</div>

## 为什么是这样一个仓库   （2–4 句：解决什么真实麻烦）
## 亮点                    （3–4 条，每条「结论 + 依据」，禁止形容词堆砌）
## 结构                    （mermaid 图，只画真实存在的模块与数据流）

…§1–§5 原样…

## 路线图                  （3–5 条，含已完成的 `[x]`）
## 参与与反馈              （Issue / PR / SECURITY 三条入口 + Star 请求）
## 许可证                  （自有代码 + 第三方说明）
```

硬性口径：

- **图只画真有的东西**：mermaid 里的节点必须能在目录或源码里找到对应文件，不画设想的模块。
- **不造数据**：亮点的依据、参数、指标一律来自仓内文档或实测记录，没有就写「未测得」，不许编。
- **徽章只用两类**：静态 `img.shields.io/badge/...`；公开仓可加 `github/last-commit`、`github/stars`。私有仓不用动态徽章（会 404）。
- **资料镜像仓例外**：`*-board-materials`、`*-reference-materials`、`hardware-course-materials` 这类仓把「为什么是这样一个仓库 / 亮点 / 结构」换成「这是什么资料 / 怎么用 / 版权与边界」，且**不得**声明 MIT。

## 4. 目录约定

- 一个工程一个目录；工程集仓库的顶层目录直接是工程名，不再套一层“源代码”等壳目录。
- 目录名用英文或中文二选一，禁止中英混用；新目录一律英文小写加下划线。
- 子工程内含固定层级：`User/`（应用）、`Drivers/`（HAL + BSP）、`Middlewares/`（FreeRTOS/LVGL 等）、`tools/`（辅助脚本）。
- **目录层级不超过 4 层**，禁止同名目录嵌套（如 `STM32工程模板(基地版)/STM32工程模板(基地版)/`）。历史嵌套在清理时以最内层为准。
- 路径总长控制在 200 字符以内（Windows 默认 260 上限，超过会导致 clone 失败）。

### 4.1 驱动与硬件描述（支撑库约定）

- 芯片级驱动统一放 `bsp-libs/drivers/<chip>/`（`src/` + `inc/` + `driver.json` + `README.md`），工程仓里不再各存一份。
- 每块板子的接线与器件用 `bsp-libs/hardware/<board>/pinmap.csv` + `BOM.csv` 描述，工程仓 README 只引用，不重复抄表。
- 提交驱动或改接线后跑 `bsp-libs/tools/check-driver.ps1`，引脚冲突、文件缺失会直接报错。
- 排错记录写在各仓 README 的“常见问题”段，由 `notes` 仓脚本汇总，避免同一坑在多仓各写一遍。

## 5. 提交约定

- 一次提交只做一件事：`新增：xxx` / `修复：xxx` / `整理：xxx`。
- 绝不提交编译产物、IDE 缓存、固件镜像、数据集与模型权重。
- 动了目录必须同一次提交里改 README。

## 6. 发布约定

- 结项工程打 tag（如 `v1.0-course`），固件 `.hex/.bin` 作为 Release 附件，不放仓库里。

## 7. 体检

`pwsh -File .\tools\repo-audit.ps1` 可一次性检查全部仓库的必备文件、README 五段、topics 数量、描述、排除摘要与赘余 CSV，输出合规/需修清单；加 `-WriteReport` 会用 `repo-audit-report.md` 落盘。

外观层（§3.1）目前**人工核对**：徽章是否有死链、mermaid 节点是否真实存在、路线图是否有已完成项。等体检脚本补上这三项检查后，纳入自动跑。

## 8. 新建仓库 checklist

1. 按 §1 命名，描述写成「一句话定位」，topics ≥ 3 且来自 [`TOPICS.md`](TOPICS.md)。
2. 建 `README.md`：头部块 + 五段 + 尾块（§3.1），外加 `CONTRIBUTING.md`、`SECURITY.md`、`.github/` 两个模板。
3. 建 `LICENSE`、`.gitignore`、`.gitattributes`；含第三方资料时用「保留所有权利 + 第三方说明」。
4. 在 `tools/catalog-rules.json` 登记分类 / 芯片 / 板卡 / 状态，重跑 `tools/build-index.ps1`。
5. 跑 `tools/repo-audit.ps1` 与 `tools/health-check.ps1`，清零后再提交。
