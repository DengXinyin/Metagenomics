#!/bin/bash
datadir=${1}
megahit_dir=${2}
binning_dir=${3}

mkdir -p ${binning_dir}
awk 'NR!=1 {print}' ${datadir}/sample.txt|while read id;do
  sample=`echo ${id}|cut -d " " -f 2|tr -d '\n\r'`
  echo "${binning_dir}/${sample}" >> ${binning_dir}/sample.name.txt
done
parallel --verbose -j 6 --memfree 30G --xapply \
	"gunzip -c {1} > {1.}
   gunzip -c {2} > {2.}
   metawrap binning -o {4}_initial_bins -t 12 -a {3}/final.contigs.fa \
   --metabat2 --maxbin2 --concoct --universal {1.} {2.}
   metawrap bin_refinement -o {4}_bins_refinem -t 12 -A {4}_initial_bins/metabat2_bins/ \
   -B {4}_initial_bins/maxbin2_bins/ -C {4}_initial_bins/concoct_bins/ -c 75 -x 25
   " \
	:::: ${megahit_dir}/sample1.txt :::: ${megahit_dir}/sample2.txt \
  :::: ${megahit_dir}/sample.name.txt :::: ${binning_dir}/sample.name.txt
mkdir -p ${binning_dir}/drep_pre
awk 'NR!=1 {print}' ${datadir}/sample.txt|while read id;do
  sample=$(echo ${id}|cut -d " " -f 2|tr -d '\n\r')
  ls ${binning_dir}/${sample}_bins_refinem/metawrap_75_25_bins/bin.*.fa|while read file;do
    if [[ -n "$file" ]]; then
      basefile=$(basename ${file})
      finalfile=bin.${sample}.${basefile#bin.}
      mv ${file} ${binning_dir}/${sample}_bins_refinem/metawrap_75_25_bins/${finalfile} || echo "Failed to move ${file}"
      cp -r ${binning_dir}/${sample}_bins_refinem/metawrap_75_25_bins/${finalfile} ${binning_dir}/drep_pre
    fi
  done
done