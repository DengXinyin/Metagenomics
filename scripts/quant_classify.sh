#!/bin/bash
datadir=${1}
cle_hodir=${2}
drep_dir=${3}
megahit_dir=${4}
host=${5}

export LD_LIBRARY_PATH=/db/lib:$LD_LIBRARY_PATH
export PATH="/db/taxator-tk_1.5.0e-64bit/bin:$PATH"
metawrap classify_bins -b ${drep_dir}/drep/dereplicated_genomes -o bin_classfication -t 42
sed -i $'1i\tbin\ttaxonomy' bin_classfication/bin_taxonomy.tab
metawrap quant_bins -b ${drep_dir}/drep/dereplicated_genomes -t 42 -o quant_bins ${cle_hodir}/*.fastq
mkdir blobology
awk 'NR!=1 {print}' ${datadir}/sample.txt|while read id;do
    sample=`echo ${id}|cut -d " " -f 2|tr -d '\n\r'`
    mkdir ${drep_dir}/${sample}
    cp ${drep_dir}/drep/dereplicated_genomes/bin.${sample}.[0-9]*.fa ${drep_dir}/${sample}
    echo "${drep_dir}/${sample}" >> ${drep_dir}/sample.name.txt
    echo "blobology/${sample}" >> blobology/sample.name.txt
    # if [ "$(ls -A ${drep_dir}/${sample})" ]; then
    #     if [ "${host}" = 'none' ];then
    #         metawrap blobology -a ${megahit_dir}/${sample}/final.contigs.fa -t 42 -o blobology/${sample} \
    #         --bins ${drep_dir}/${sample} ${cle_hodir}/${sample}_clean*.fastq
    #     else
    #         metawrap blobology -a ${megahit_dir}/${sample}/final.contigs.fa -t 42 -o blobology/${sample} \
    #         --bins ${drep_dir}/${sample} ${cle_hodir}/${sample}_dehost*.fastq
    #     fi
    # fi
done
parallel --verbose -j 6 --memfree 30G --xapply \
   'if [ "$(ls -A {4})" ]; then
        echo "Processing {3}" >> parallel_log.txt
        metawrap blobology -a {3}/final.contigs.fa -t 12 -o {5} --bins {4} {1.} {2.}
    else
        echo "Skipping {3}, directory {4} is empty" >> parallel_log.txt
    fi' \
	:::: ${megahit_dir}/sample1.txt :::: ${megahit_dir}/sample2.txt \
    :::: ${megahit_dir}/sample.name.txt :::: ${drep_dir}/sample.name.txt :::: blobology/sample.name.txt
for file in blobology/*/final.contigs.binned.blobplot; do
    awk -F'\t' 'NR!=1 {print $1,$2,$3,$4,$12}' OFS='\t' ${file} > ${file}.tmp
done
cat blobology/*/final.contigs.binned.blobplot.tmp > blobology/all.binned.blobplot.txt
sed -i $'1i\seqid\tlen\tgc\tcoverage\tbin' blobology/all.binned.blobplot.txt
