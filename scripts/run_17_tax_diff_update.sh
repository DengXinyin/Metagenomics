#!/bin/bash
# ============================================================
# Task 17: tax_diff (update)
# 用法: bash run_17_tax_diff_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 17: tax_diff (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 17: tax_diff
# 切换批次：改 TEST_RUN 的值（test1 / test2 / test3）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 17_tax_diff_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#

sudo docker run --network=host --rm -it --cpus=24 --memory="320g" \
    -v /home/xydeng/Metagenomics/metadatadir:/metadatadir:ro \
    -v /home/xydeng/Metagenomics/scripts:/scripts:ro \
    -v /home/xydeng/Metagenomics/scripts_dxy/Script:/root/microbiome/microbiome/metage_megahit:ro \
    -e METAGE_SCRIPTS_PATH=/scripts \
    -v /home/xydeng/Metagenomics:/home/xydeng/Metagenomics \
    -e TEST_RUN=${TEST_RUN} \
    192.168.30.202:23099/metage_megahit/metage:v2.87 \
    bash -c "
        set -euo pipefail
        echo '=========================================='
        echo '开始时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python -c 'import sklearn, matplotlib, seaborn, plotly' 2>/dev/null || pip install --quiet scikit-learn matplotlib seaborn plotly
        echo '=== 开始运行 tax_diff 优化版 ==='
        time python /root/microbiome/microbiome/metage_megahit/tax_base_update.py \
            -I /metadatadir --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/original/Annotation \
            --pre_resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update_Result
        time python /root/microbiome/microbiome/metage_megahit/tax_diff_update.py \
            -I /metadatadir --pre_resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update_Result \
            --tpmdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update
        time python /root/microbiome/microbiome/metage_megahit/alpha_diver_update.py \
            -I /metadatadir --tpmdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update_Result
        set -u
        time python /root/microbiome/microbiome/metage_megahit/tax_lefse_update.py \
            -I /metadatadir --pre_resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --res_dir /home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update_Result \
            --tpmdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update
        echo '=========================================='
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /home/xydeng/Metagenomics/scripts_dxy/Script/sample_double_check.py record-stage \
            -I /home/xydeng/Metagenomics/project/demo/metadatadir \
            --stage tax_diff \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files Result=/home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update_Result --files tpmdir=/home/xydeng/Metagenomics/results_\${TEST_RUN}/17_tax_diff/update "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/17_tax_diff_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/17_tax_diff_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
