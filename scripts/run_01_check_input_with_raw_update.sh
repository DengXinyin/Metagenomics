#!/bin/bash
# ============================================================
# Task 01: check_input_with_raw (update)
# 用法: bash run_01_check_input_with_raw_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 01: check_input_with_raw (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 01: check_input_with_raw
# 切换批次：改 TEST_RUN 的值（test1 / test2 / test3）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 01_check_input_with_raw_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#   重新接入：tmux attach -t 01_check_input_with_raw_${TEST_RUN}
#

sudo docker run --network=host --rm -it --cpus=12 --memory="20g" \
    -v /home/xydeng/Metagenomics/project/demo/data:/data:ro \
    -v /home/xydeng/Metagenomics/project/demo/rawdata:/rawdata:ro \
    -v /home/xydeng/Metagenomics/scripts_dxy/Script:/scripts:ro \
    -v /home/xydeng/Metagenomics/metadatadir:/metadatadir \
    192.168.30.202:23099/metage_megahit/metage:v2.87 \
    bash -c "
        echo '==========================================' "
        echo '开始时间: ' && date '+%Y-%m-%d %H:%M:%S' "
        echo '==========================================' "
        echo '=== 检查输入文件 ===' "
        ls -la /data/data.xlsx "
        echo 'fastq 文件数: ' && ls /rawdata/*.fq.gz | wc -l "
        echo '=== 开始运行 dealdata.py 和 check_fastq_mapping_update.py ===' "
        time (python /scripts/dealdata.py -indir /data -outdir /metadatadir && python /scripts/check_fastq_mapping_update.py /rawdata /metadatadir/sample.txt /metadatadir/sample-metadata.tsv) "
        echo '==========================================' "
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S' "
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        python3 /scripts/sample_double_check.py record-stage \
            -I /metadatadir \
            --stage check_input_with_raw \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files sample_txt=/metadatadir/sample.txt \
                    metadata=/metadatadir/sample-metadata.tsv "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/01_check_input_with_raw_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/01_check_input_with_raw_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
