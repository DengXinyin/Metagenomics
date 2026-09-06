#!/bin/bash
# ============================================================
# Task 16: func_base (update)
# 用法: bash run_16_func_base_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 16: func_base (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 16: func_base
# 切换批次：改 TEST_RUN 的值（test1 / test2 / test3）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 16_func_base_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#

sudo docker run --network=host --rm -it --cpus=24 --memory="320g" \
    -v /home/xydeng/Metagenomics/metadatadir:/metadatadir:ro \
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
        conda activate py39
        echo '=== 开始运行 func_base 优化版（7个统计脚本）==='
        time python /root/microbiome/microbiome/metage_megahit/func_stats_update.py \
            -I /metadatadir --Annotation /home/xydeng/Metagenomics/results_\${TEST_RUN}/12_anno/update/Annotation \
            --dbdir /metagenome-DB/database \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update
        time python /root/microbiome/microbiome/metage_megahit/CycDB_stats_update.py \
            -I /metadatadir --CycDB /home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/CycDB \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update
        time python /root/microbiome/microbiome/metage_megahit/ARGs_stats_update.py \
            -I /metadatadir --ARGdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/ARGs \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update
        time python /root/microbiome/microbiome/metage_megahit/vfdb_stats_update.py \
            -I /metadatadir --vfdb_dir /home/xydeng/Metagenomics/results_\${TEST_RUN}/13_VCA_anno/update/VFDB \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update
        time python /root/microbiome/microbiome/metage_megahit/mobileOG_stats_update.py \
            -I /metadatadir --mobileOGdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/mobileOGs \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update
        time python /root/microbiome/microbiome/metage_megahit/BacMet2_stats_update.py \
            -I /metadatadir --BacMet2dir /home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/BacMet2 \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update
        time python /root/microbiome/microbiome/metage_megahit/QS_stats_update.py \
            -I /metadatadir --QSdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/14_MBQ_anno/update/QS \
            --resdir /home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update \
            --func_tmp /home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update
        echo '=========================================='
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S'
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /home/xydeng/Metagenomics/scripts_dxy/Script/sample_double_check.py record-stage \
            -I /home/xydeng/Metagenomics/project/demo/metadatadir \
            --stage func_base \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files Result=/home/xydeng/Metagenomics/results_\${TEST_RUN}/19_coll_res/update --files func_tmp=/home/xydeng/Metagenomics/results_\${TEST_RUN}/16_func_base/update "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/16_func_base_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/16_func_base_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
