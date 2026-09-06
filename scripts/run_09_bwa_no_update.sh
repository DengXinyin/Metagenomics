#!/bin/bash
# ============================================================
# Task 09: bwa_no (update)
# 用法: bash run_09_bwa_no_update.sh [test1|test2|test3]
# 默认: test1
# ============================================================
set -euo pipefail

TEST_RUN="${1:-test1}"
echo "=========================================="
echo "  Task 09: bwa_no (update)"
echo "  批次: ${TEST_RUN}"
echo "  开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

cd /home/xydeng/Metagenomics

# Task 09: bwa_no
# 切换批次：改 TEST_RUN 的值（test1 / test2）
#
# 运行方式：
#   cd /home/xydeng/Metagenomics
#   TEST_RUN="test1"
#   tmux new -s 09_bwa_no_${TEST_RUN}
#   粘贴下面的 sudo docker run 命令
#   Ctrl+B D 退出 tmux
#

sudo docker run --network=host --rm -it --cpus=72 --memory="720g" \
    -v /home/xydeng/Metagenomics/metadatadir:/metadatadir:ro \
    -v /home/xydeng/Metagenomics/results_${TEST_RUN}/02_kneaddata_no/cleandata:/cleandata:ro \
    -v /home/xydeng/Metagenomics/results_${TEST_RUN}/02_kneaddata_no/de_host:/de_host:ro \
    -v /home/xydeng/Metagenomics/results_${TEST_RUN}/08_prodig_no/update:/prodigal:ro \
    -v /home/xydeng/Metagenomics/scripts:/scripts:ro \
    -v /home/xydeng/Metagenomics/scripts_dxy/Script:/root/microbiome/microbiome/metage_megahit:ro \
    -e METAGE_SCRIPTS_PATH=/scripts \
    -v /home/xydeng/Metagenomics:/workdir \
    -e TEST_RUN=${TEST_RUN} \
    192.168.30.202:23099/metage_megahit/metage:v2.87 \
    bash -c "
        HOST=\"none\"
        echo '==========================================' "
        echo '开始时间: ' && date '+%Y-%m-%d %H:%M:%S' "
        echo '==========================================' "
        source /root/anaconda3/etc/profile.d/conda.sh "
        conda activate biobakery "
        echo '=== 检查输入文件 ===' "
        ls -la /metadatadir/sample.txt "
        ls -la /prodigal/unique_gene.fasta "
        echo '=== 开始运行 bwa_update ===' "
        time python /root/microbiome/microbiome/metage_megahit/bwa_update.py \
            -I /metadatadir \
            --cleandir /cleandata \
            --host \${HOST} \
            --prodigal /prodigal \
            --host_dir /de_host \
            --bowtie /workdir/results_\${TEST_RUN}/09_bwa_no/update "
        echo '==========================================' "
        echo '结束时间: ' && date '+%Y-%m-%d %H:%M:%S' "
        echo '=========================================='
        echo '=== 记录输出文件指纹 ===' "
        for sample in CK-1 CK-2 CK-3 T-1 T-2 T-3; do \
            python3 /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
                -I /metadatadir \
                --stage bwa_no \
                --key update \
                --no-md5 \
                --input-samples \$sample \
                --files bam=/workdir/results_\${TEST_RUN}/09_bwa_no/update/\$sample.sort.bam \
            || true \
        done "
        python3 /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I /metadatadir \
            --stage bwa_no \
            --key update \
            --merged \
            --no-md5 \
            --input-samples CK-1 CK-2 CK-3 T-1 T-2 T-3 \
            --files gene_count=/workdir/results_\${TEST_RUN}/09_bwa_no/update/gene_count.csv \
                    gene_tpm=/workdir/results_\${TEST_RUN}/09_bwa_no/update/gene_tpm.csv "
        echo '=== 指纹记录完成 ===' "
    " 2>&1 | tee /home/xydeng/Metagenomics/scripts_dxy/logs/09_bwa_no_update_${TEST_RUN}_runtime.log

echo ""
echo "=========================================="
echo "  结束时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
echo ""
echo "=== 运行时间 ==="
grep "^real" /home/xydeng/Metagenomics/scripts_dxy/logs/09_bwa_no_update_${TEST_RUN}_runtime.log 2>/dev/null || echo "(从上方输出查看 real 时间)"
