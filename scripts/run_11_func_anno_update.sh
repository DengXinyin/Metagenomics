#!/bin/bash
# ============================================================
# Task 11: func_anno (update)
# 用法: bash run_11_func_anno_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 11: func_anno (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 11: func_anno
# 切换批次：改 TEST_RUN 的值（test1 / test2）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 11_func_anno_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#

sudo docker run --network=host --rm -it --cpus=62 --memory="720g" \
    -v /home/xydeng/Metagenomics/results_${TEST_RUN}/08_prodig_no/update:/prodigal:ro \
    -v /data/data2/metagenome-DB:/metagenome-DB:ro \
    -v /home/xydeng/Metagenomics/scripts:/scripts:ro \
    -v /home/xydeng/Metagenomics/scripts_dxy/Script:/root/microbiome/microbiome/metage_megahit:ro \
    -e METAGE_SCRIPTS_PATH=/scripts \
    -v /home/xydeng/Metagenomics:/workdir \
    -v /home/xydeng/Metagenomics/project/demo/metadatadir:/metadatadir \
    -e TEST_RUN=${TEST_RUN} \
    192.168.30.202:23099/metage_megahit/metage:v2.87 \
    bash -c "
        set -euo pipefail
        echo '=========================================='
        echo '开始时间: '
        date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        echo '=== 检查输入文件 ==='
        ls -la /prodigal/unique_gene.fasta
        ls -la /metagenome-DB/database/eggNOG
        ls -la /app/eggnog-mapper/emapper.py
        echo '=== 开始运行 func_anno 优化版 ==='
        time python /root/microbiome/microbiome/metage_megahit/func_ano_1_update.py \
            --prodigal /prodigal \
            --dbdir /metagenome-DB/database \
            --Annotation /workdir/results_\${TEST_RUN}/11_func_anno/update \
            --cpu 50 \
            --evalue 1e-5 \
            --prefix func
        echo '=========================================='
        echo '结束时间: '
        date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I /metadatadir \
            --stage func_anno \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files Annotation=/workdir/results_\${TEST_RUN}/11_func_anno/update "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/11_func_anno_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/11_func_anno_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
