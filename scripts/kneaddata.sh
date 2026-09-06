#!/bin/bash
source ~/anaconda3/etc/profile.d/conda.sh
conda activate biobakery
datadir=${1}
mapdir=${2}
cleandatadir=${3}
host_dir=${4}
host_str=${5}

awk 'NR!=1 {print}' ${datadir}/sample.txt|while read id;do
    sample=`echo ${id}|cut -d " " -f 2|tr -d '\n\r'`
    echo ${sample}
	  bowtie2 -p 64 --no-unal \
	  -x ${mapdir}/${host_str} \
	  -1 ${cleandatadir}/${sample}_clean_1.fastq.gz \
	  -2 ${cleandatadir}/${sample}_clean_2.fastq.gz \
	  --un-conc-gz ${host_dir}/${sample}_de_host.fastq.gz
	  mv ${host_dir}/${sample}_de_host.fastq.1.gz ${host_dir}/${sample}_dehost_1.fastq.gz
    mv ${host_dir}/${sample}_de_host.fastq.2.gz ${host_dir}/${sample}_dehost_2.fastq.gz
    fastp -Q -L -A --thread 64 \
    -i ${host_dir}/${sample}_dehost_1.fastq.gz -I ${host_dir}/${sample}_dehost_2.fastq.gz \
    -o ${cleandatadir}/${sample}_rm_1.fastq.gz -O ${cleandatadir}/${sample}_rm_2.fastq.gz \
    -h ${host_dir}/${sample}.html -j ${host_dir}/${sample}.json
done
rm ${cleandatadir}/*clean*.fastq.gz
rm ${cleandatadir}/*rm*.fastq.gz
mv ${host_dir}/*.json ${host_dir}/qc
mv ${host_dir}/*.html ${host_dir}/qc


