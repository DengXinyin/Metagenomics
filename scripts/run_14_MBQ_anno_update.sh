#!/bin/bash
# ============================================================
# Task 14: MBQ_anno (update)
# 用法: bash run_14_MBQ_anno_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 14: MBQ_anno (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 14: MBQ_anno
# 切换批次：改 TEST_RUN 的值（test1 / test2 / test3）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 14_MBQ_anno_${TEST_RUN}
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
        echo '=== MBQ_anno 三工具并行 ==='
        time python /root/microbiome/microbiome/metage_megahit/mobileOG_update.py \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update/Annotation \
            --mobileOGdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/mobileOGs \
            --prodigal /home/xydeng/Metagenomics/results_\${TEST_RUN}/08_prodig_no/update \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --dbdir /metagenome-DB/database &
        MOBILEOG_PID=\$!
        time python /root/microbiome/microbiome/metage_megahit/BacMet2_update.py \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update/Annotation \
            --BacMet2dir /home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/BacMet2 \
            --prodigal /home/xydeng/Metagenomics/results_\${TEST_RUN}/08_prodig_no/update \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --dbdir /metagenome-DB/database &
        BACMET2_PID=\$!
        time python /root/microbiome/microbiome/metage_megahit/QS_update.py \
            --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update/Annotation \
            --QSdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/QS \
            --prodigal /home/xydeng/Metagenomics/results_\${TEST_RUN}/08_prodig_no/update \
            --bowtie /home/xydeng/Metagenomics/results_\${TEST_RUN}/09_bwa_no/update \
            --dbdir /metagenome-DB/database &
        QS_PID=\$!
        wait \$MOBILEOG_PID \$BACMET2_PID \$QS_PID
        echo '=========================================='
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /home/xydeng/Metagenomics/scripts_dxy/Script/sample_double_check.py record-stage \
            -I /home/xydeng/Metagenomics/project/demo/metadatadir \
            --stage MBQ_anno \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files mobileOGs=/home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/mobileOGs --files BacMet2=/home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/BacMet2 --files QS=/home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/QS "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/14_MBQ_anno_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/14_MBQ_anno_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
