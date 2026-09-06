#!/bin/bash
# ============================================================
# 宏基因组原始 WDL 测试运行脚本
# ============================================================
set -euo pipefail

# 工作目录
WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${WORK_DIR}"

# Cromwell jar 路径（如不存在会自动下载到当前目录）
# Java 路径：Cromwell 85 需要 Java 11+，系统默认 java 为 1.8
JAVA_BIN="/home/software/Software/Java/v20.0.1/bin/java"
CROMWELL_JAR="${WORK_DIR}/cromwell-85.jar"
WDL_FILE="${WORK_DIR}/metage_megahit.wdl"
INPUTS_JSON="${WORK_DIR}/metage_megahit.inputs.json"
OPTIONS_JSON="${WORK_DIR}/options.json"
CONFIG_FILE="${WORK_DIR}/cromwell.conf"
METADATA_FILE="${WORK_DIR}/cromwell_metadata_$(date +%Y%m%d_%H%M%S).json"
LOG_FILE="${WORK_DIR}/cromwell_run_$(date +%Y%m%d_%H%M%S).log"

# 校验 Java 版本
if [ ! -x "${JAVA_BIN}" ]; then
    echo "错误：找不到可用的 Java 11+ 路径 ${JAVA_BIN}" >&2
    exit 1
fi
JAVA_VERSION=$("${JAVA_BIN}" -version 2>&1 | head -1 | sed 's/.*"\(.*\)".*/\1/')
echo ">>> 使用 Java: ${JAVA_VERSION} (${JAVA_BIN})"

# 校验 Cromwell jar
if [ ! -f "${CROMWELL_JAR}" ]; then
    echo "错误：找不到 ${CROMWELL_JAR}，请手动上传或下载 Cromwell 85 jar" >&2
    exit 1
fi

# 校验输入文件
for f in "${WDL_FILE}" "${INPUTS_JSON}" "${OPTIONS_JSON}"; do
    if [ ! -f "${f}" ]; then
        echo "错误：缺少文件 ${f}" >&2
        exit 1
    fi
done

echo ">>> 开始运行 Cromwell 工作流"
echo "    WDL:       ${WDL_FILE}"
echo "    Inputs:    ${INPUTS_JSON}"
echo "    Options:   ${OPTIONS_JSON}"
echo "    Metadata:  ${METADATA_FILE}"
echo "    Log:       ${LOG_FILE}"

# 构建 cromwell 命令
CROMWELL_CMD=(
    "${JAVA_BIN}" -Xmx4g
)

# 如存在自定义 cromwell.conf 则通过 JVM 参数加载
if [ -f "${CONFIG_FILE}" ]; then
    echo "    Config:    ${CONFIG_FILE}"
    CROMWELL_CMD+=( -Dconfig.file="${CONFIG_FILE}" )
fi

CROMWELL_CMD+=(
    -jar "${CROMWELL_JAR}" run
    -i "${INPUTS_JSON}"
    -o "${OPTIONS_JSON}"
    -m "${METADATA_FILE}"
    "${WDL_FILE}"
)

# 运行 Cromwell（将 stdout/stderr 同时输出到日志）
"${CROMWELL_CMD[@]}" 2>&1 | tee "${LOG_FILE}"

echo ">>> 工作流运行结束"
echo "    日志：     ${LOG_FILE}"
echo "    Metadata：${METADATA_FILE}"
