#!/bin/bash
# ============================================================
# Task 18: func_diff (update)
# 用法: bash run_18_func_diff_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 18: func_diff (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 18: func_diff
# 切换批次：改 TEST_RUN 的值（test1 / test2 / test3）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 18_func_diff_${TEST_RUN}
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
        set -eo pipefail
        echo '=========================================='
        echo '开始时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python -c 'import sklearn, matplotlib, seaborn, plotly' 2>/dev/null || pip install --quiet scikit-learn matplotlib seaborn plotly
        echo '=== 开始运行 func_diff 优化版 ==='
        time python /root/microbiome/microbiome/metage_megahit/func_base_update.py \
            -I /metadatadir --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update
        time python /root/microbiome/microbiome/metage_megahit/func_diff_update.py \
            -I /metadatadir --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update \
            --func_diff /home/xydeng/Metagenomics/results_\${TEST_RUN}/18_func_diff/update \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update
        set +u
        conda activate lefse
        set -u
        time python /root/microbiome/microbiome/metage_megahit/func_lefse_update.py \
            -I /metadatadir --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update \
            --func_diff /home/xydeng/Metagenomics/results_\${TEST_RUN}/18_func_diff/update \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update
        echo '=========================================='
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /home/xydeng/Metagenomics/scripts_dxy/Script/sample_double_check.py record-stage \
            -I /home/xydeng/Metagenomics/project/demo/metadatadir \
            --stage func_diff \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files Result=/home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update --files func_diff=/home/xydeng/Metagenomics/results_\${TEST_RUN}/18_func_diff/update "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/18_func_diff_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/18_func_diff_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
