#!/bin/bash
# ============================================================
# Task 13: VCA_anno (update)
# 用法: bash run_13_VCA_anno_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 13: VCA_anno (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 13: VCA_anno
# 切换批次：改 TEST_RUN 的值（test1 / test2 / test3）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 13_VCA_anno_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#

sudo docker run --network=host --rm -it --cpus=32 --memory="512g" \
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
        cd /home/xydeng/Metagenomics
        echo '=== VCA_anno 三工具并行 ==='
        time python /root/microbiome/microbiome/metage_megahit/vfdb_update.py \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update/Annotation \
            --VFDB /home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/VFDB \
            --prodigal /home/xydeng/Metagenomics/results_\${TEST_RUN}/08_prodig_no/update \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --dbdir /metagenome-DB/database &
        VFDB_PID=\$!
        time python /root/microbiome/microbiome/metage_megahit/CycDB_update.py \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update/Annotation \
            --CycDB /home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/CycDB \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --dbdir /metagenome-DB/database &
        CYCDB_PID=\$!
        time python /root/microbiome/microbiome/metage_megahit/ARGs_update.py \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update/Annotation \
            --ARGdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/ARGs \
            --prodigal /home/xydeng/Metagenomics/results_\${TEST_RUN}/08_prodig_no/update \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --dbdir /metagenome-DB/database &
        ARGS_PID=\$!
        wait \$VFDB_PID \$CYCDB_PID \$ARGS_PID
        echo '=========================================='
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /home/xydeng/Metagenomics/scripts_dxy/Script/sample_double_check.py record-stage \
            -I /home/xydeng/Metagenomics/project/demo/metadatadir \
            --stage VCA_anno \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files VFDB=/home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/VFDB --files CycDB=/home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/CycDB --files ARGs=/home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/ARGs "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/13_VCA_anno_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/13_VCA_anno_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
