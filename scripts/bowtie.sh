datadir=${1}
cle_hodir=${2}
prodigal_dir=${3}
bowtie_dir=${4}
type=${5}

awk 'NR!=1 {print}' ${datadir}/sample.txt|while read id;do
  sample=`echo ${id}|cut -d " " -f 2|tr -d '\n\r'`
  if [ "${type}" = 'none' ];then
    echo "${cle_hodir}/${sample}_clean_1.fastq.gz" >> ${bowtie_dir}/sample1.txt
    echo "${cle_hodir}/${sample}_clean_2.fastq.gz" >> ${bowtie_dir}/sample2.txt
  else
    echo "${cle_hodir}/${sample}_dehost_1.fastq.gz" >> ${bowtie_dir}/sample1.txt
    echo "${cle_hodir}/${sample}_dehost_2.fastq.gz" >> ${bowtie_dir}/sample2.txt
  fi
  echo "${bowtie_dir}/${sample}" >> ${bowtie_dir}/sample.name.txt
done
bowtie2-build --threads 72 -f ${prodigal_dir}/unique_gene.fasta ${bowtie_dir}/uniq
parallel -j 7 --memfree 50G --xapply \
	'bowtie2 -p 12 -x {1} -1 {2} -2 {3} -S {4}.sam' \
	::: "${bowtie_dir}/uniq" \
	:::: ${bowtie_dir}/sample1.txt :::: ${bowtie_dir}/sample2.txt :::: ${bowtie_dir}/sample.name.txt
parallel -j 7 --memfree 50G --xapply \
  "samtools sort -@12 {1}.sam -o {1}.sort.bam
   samtools index {1}.sort.bam
   samtools idxstats {1}.sort.bam > {1}_mapped.txt
   sed -i '1i\GeneID\t\length\tmapped_read\tunmapped_read' {1}_mapped.txt
   cut -f 1-3 {1}_mapped.txt > {1}_mapped_cut.txt" \
  :::: ${bowtie_dir}/sample.name.txt
