# WDL_original 原始宏基因组流程测试目录

本目录用于对原始宏基因组分析流程 `metage_megahit.wdl` 进行本地化测试。

## 目录内容

```
WDL_original/
├── metage_megahit.wdl              # 原始 WDL 工作流文件
├── metage_megahit.inputs.json      # Cromwell 输入参数配置
├── options.json                    # Cromwell 运行选项
├── cromwell.conf                   # 可选：Cromwell Local + Docker 后端配置（默认配置已支持 Docker）
├── data.xlsx                       # 样本元数据（sample / comparison 两个 sheet）
├── report_no.txt                   # 报告编号占位文件
├── create_metadata.py              # 生成 data.xlsx 的脚本
├── run_cromwell.sh                 # 一键运行脚本
├── cromwell-85.jar                 # Cromwell 引擎（运行脚本会自动下载）
└── README.md                       # 本说明文件
```

## 测试数据

- **原始 FASTQ**：`/home/xydeng/Metagenomics_Docker/data`
  - 12 个样本，每个样本 R1/R2 双端数据
  - 命名格式：`{SampleID}_R1.fq.gz` / `{SampleID}_R2.fq.gz`
- **元数据**：`data.xlsx`
  - `sample` sheet：样本名、fastq 基名、分组
  - `comparison` sheet：定义差异分析比较组

### 分组设计

| 样本名 | 分组 |
|--------|------|
| RCK1-3, SCK1-3 | CK（对照） |
| RS1-3, SS1-3   | S（处理）  |

比较组：`Treatment`（CK vs S）

> 如需调整分组或比较方案，请修改 `create_metadata.py` 后重新运行生成 `data.xlsx`。

## Docker 镜像

工作流主要使用镜像：

```
192.168.30.202:23099/metage_megahit/metage:v2.87
```

> 注：WDL 中 `bins` 与 `quant_classify` 两个 task 仍使用 `metawrap:v1.79` 镜像（原流程设定），其余 task 已使用上述 metage:v2.87 镜像。

## 数据库路径

```
/cephfs_data/genostack_v3/genostack_php/public_file_data/metagenome-DB
```

该路径在运行时会通过 Cromwell 的 Local + Docker 后端挂载到容器内。

## Java 版本要求

Cromwell 85 需要 **Java 11 或更高版本**。当前系统默认 `java` 为 1.8，因此运行脚本已指定使用：

```
/home/software/Software/Java/v20.0.1/bin/java
```

如需更换 Java 路径，请修改 `run_cromwell.sh` 中的 `JAVA_BIN` 变量。

## 运行方式

### 1. 直接运行

```bash
cd /home/xydeng/Metagenomics_Docker/WDL_original
bash run_cromwell.sh
```

脚本会自动检测并下载 `cromwell-85.jar`，然后提交工作流。

### 2. 手动运行

```bash
cd /home/xydeng/Metagenomics_Docker/WDL_original

# 运行工作流（使用 Java 20，并加载 cromwell.conf）
/home/software/Software/Java/v20.0.1/bin/java -Xmx4g -Dconfig.file=cromwell.conf -jar cromwell-85.jar run \
    -i metage_megahit.inputs.json \
    -o options.json \
    -m cromwell_metadata_$(date +%Y%m%d_%H%M%S).json \
    metage_megahit.wdl
```

## 资源说明

原始 WDL 中部分 task 资源需求较高：

| Task | CPU | 内存 |
|------|-----|------|
| megahit_no | 96 | 720 GB |
| bwa_no | 72 | 720 GB |
| tax_anno / func_anno | 62 | 720 GB |
| prodig_no | 72 | 640 GB |

**当前测试机配置**：192 CPU / 503 GB 内存。

若资源不足，可临时调低 `metage_megahit.wdl` 中对应 task 的 `cpu` 和 `memory` 值（仅用于测试），但正式流程请保持原配置。

## 输出

- 工作流日志：`cromwell_run_YYYYMMDD_HHMMSS.log`
- 最终结果目录：`outputs/`（由 `options.json` 中的 `final_workflow_outputs_dir` 指定）

## 已知问题与修复

### kneaddata_no 任务在 host="none" 时失败

**现象**：`kneaddata_no` 实际运行完成后，Cromwell 报错：

```text
FileNotFoundException: Could not process output, file not found: .../call-kneaddata_no/execution/de_host
```

**原因**：`Kneaddata.py` 在 `--host none` 时不会创建 `de_host` 目录，但 WDL 的 `kneaddata_no` task 将 `File dohost_dir="de_host"` 作为必需输出。

**修复**：已在 `metage_megahit.wdl` 的 `kneaddata_no` task 末尾增加：

```wdl
if [ "${host}" = "none" ] && [ ! -d de_host ]; then mkdir -p de_host; fi
```

原始 WDL 已备份为 `metage_megahit.wdl.original`。

## 注意事项

1. 运行前请确认 Docker 服务可用，并能拉取 `192.168.30.202:23099/metage_megahit/metage:v2.87`。
2. 确认数据库路径 `/cephfs_data/.../metagenome-DB` 对当前用户可读。
3. 本目录中的 `data.xlsx`、`report_no.txt`、`inputs.json`、`options.json` 均为测试配置，可根据实际需求修改。
4. 当前 `metage_megahit.wdl` 已针对 `host="none"` 做最小修复，与原始流程逻辑一致。
