#!/bin/bash
# ============================================================
# Task 02: kneaddata_no (update)
# 用法: bash run_02_kneaddata_no_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 02: kneaddata_no (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 02: kneaddata_no
# 切换批次：改 TEST_RUN 的值（test1 / test2）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 02_kneaddata_no_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#   重新接入：tmux attach -t 02_kneaddata_no_${TEST_RUN}
#

sudo docker run --network=host --rm -it --cpus=32 --memory="320g" \
    -v /home/xydeng/Metagenomics/project/demo/data:/data:ro \
    -v /home/xydeng/Metagenomics/project/demo/rawdata:/rawdata:ro \
    -v /home/xydeng/Metagenomics/metadatadir:/metadatadir:ro \
    -v /home/xydeng/Metagenomics/scripts_dxy/Script:/scripts:ro \
    -v /home/xydeng/Metagenomics/scripts_dxy/Script:/root/microbiome/microbiome/metage_megahit:ro \
    -v /home/xydeng/Metagenomics/results_${TEST_RUN}/02_kneaddata_no/cleandata:/cleandata \
    -v /home/xydeng/Metagenomics/results_${TEST_RUN}/02_kneaddata_no/Result:/Result \
    -v /home/xydeng/Metagenomics/results_${TEST_RUN}/02_kneaddata_no/de_host:/de_host \
    -v /cephfs_data/genostack_v3/genostack_php/public_file_data/metagenome-DB:/db:ro \
    -e TEST_RUN=${TEST_RUN} \
    192.168.30.202:23099/metage_megahit/metage:v2.87 \
    bash -c "
        echo '==========================================' "
        echo '开始时间: ' && date '+%Y-%m-%d %H:%M:%S' "
        echo '==========================================' "
        source /root/anaconda3/etc/profile.d/conda.sh "
        conda activate biobakery "
        echo '=== 检查输入文件 ===' "
        ls /metadatadir "
        echo 'fastq 文件数: ' && ls /rawdata/*.fq.gz | wc -l "
        echo '=== 确认脚本存在 ===' "
        ls -la /scripts/QC_update.sh /scripts/Kneaddata_update.sh "
        echo '=== 开始运行 Kneaddata_update.py ===' "
        time python /scripts/Kneaddata_update.py -i /rawdata -I /metadatadir --host none --mapdir /db/database/kneaddata_database -o /cleandata --resdir /Result --host_dir /de_host "
        echo '==========================================' "
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S' "
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /scripts/sample_double_check.py record-stage \
            -I /metadatadir \
            --stage kneaddata_no \
            --key update \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files cleandata=/cleandata \
                    Result=/Result \
                    de_host=/de_host "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/02_kneaddata_no_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/02_kneaddata_no_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
