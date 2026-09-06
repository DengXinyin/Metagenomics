#!/bin/bash
# ============================================================
# Task 12: anno (update)
# 用法: bash run_12_anno_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 12: anno (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 12: anno
# 切换批次：改 TEST_RUN 的值（test1 / test2 / test3）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 12_anno_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#

sudo docker run --network=host --rm -it --cpus=24 --memory="512g" \
    -v /data/data2/metagenome-DB:/metagenome-DB:ro \
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
        conda activate biobakery
        echo '=== 检查输入文件 ==='
        ls -la /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update
        ls -la /home/xydeng/Metagenomics/results_\${TEST_RUN}/10_tax_anno/update
        ls -la /home/xydeng/Metagenomics/results_\${TEST_RUN}/11_func_anno/update
        ls -la /metagenome-DB/database/NR
        echo '=== 开始运行 anno 优化版 ==='
        mkdir -p /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update
        cd /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update
        time python /root/microbiome/microbiome/metage_megahit/tax_ano_2_update.py \
            --tax_anno /home/xydeng/Metagenomics/results_\${TEST_RUN}/10_tax_anno/update \
            --dbdir /metagenome-DB/database/NR \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update
        time python /root/microbiome/microbiome/metage_megahit/func_ano_2_update.py \
            --fun_anno /home/xydeng/Metagenomics/results_\${TEST_RUN}/11_func_anno/update \
            --dbdir /metagenome-DB/database \
            --mapdir /metagenome-DB \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update
        echo '=========================================='
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /home/xydeng/Metagenomics/scripts_dxy/Script/sample_double_check.py record-stage \
            -I /home/xydeng/Metagenomics/project/demo/metadatadir \
            --stage anno \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files Annotation=/home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/12_anno_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/12_anno_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
