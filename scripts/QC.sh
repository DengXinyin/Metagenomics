#!/bin/bash
rawdatadir=${1}
datadir=${2}
cleandatadir=${3}

awk 'NR!=1 {print}' ${datadir}/sample.txt|while read id;do
    fqn=`echo ${id}|cut -d " " -f 1|tr -d '\n\r'`
    sample=`echo ${id}|cut -d " " -f 2|tr -d '\n\r'`
    echo ${fqn}
    echo ${sample}

    for suffix in "_1.fq.gz" "_R1.fq.gz" ".1.fq.gz"  ".1.fastq.gz"  "_1.fastq.gz" "_R1.fastq.gz" ".R1.raw.fastq.gz"  ".R1.raw.fq.gz" ".R1.fq.gz" "_R1_001.fastq.gz"; do
        if [ -e "${rawdatadir}/${fqn}${suffix}" ]; then
            echo "${rawdatadir}/${fqn}${suffix}"
            echo "${fqn}_1.fastq.gz"
            ln -sf "${rawdatadir}/${fqn}${suffix}" "${fqn}_1.fastq.gz"
        fi
    done

    for suffix in "_2.fq.gz" "_R2.fq.gz" ".2.fq.gz" ".2.fastq.gz" "_2.fastq.gz"  "_R2.fastq.gz" ".R2.raw.fastq.gz" ".R2.raw.fq.gz" ".R2.fq.gz" "_R2_001.fastq.gz"; do
        if [ -e "${rawdatadir}/${fqn}${suffix}" ]; then
            ln -sf "${rawdatadir}/${fqn}${suffix}" "${fqn}_2.fastq.gz"
        fi
    done

    fastp -3 -5 -W 4 -M 20 -l 100 --thread 16 \
    -i ${fqn}_1.fastq.gz -I ${fqn}_2.fastq.gz \
    -o ${cleandatadir}/${sample}_clean_1.fastq.gz -O ${cleandatadir}/${sample}_clean_2.fastq.gz \
    -h ${cleandatadir}/${sample}.html -j ${cleandatadir}/${sample}.json
done
mv ${cleandatadir}/*.json ${cleandatadir}/qc
mv ${cleandatadir}/*.html ${cleandatadir}/qc
echo '------------clean data finish!------------'
