#!/bin/bash
datadir=${1}
binning_dir=${2}
drep_dir=${3}

mkdir -p ${drep_dir}/checkm
source /root/anaconda3/etc/profile.d/conda.sh
export PATH=/fastani/bin:$PATH
conda activate drep
dRep dereplicate ${drep_dir}/drep -nc 0.30 -p 30 --ignoreGenomeQuality -g ${binning_dir}/drep_pre/*.fa
checkm lineage_wf -x fa -t 30 --tab_table -f ${drep_dir}/checkm/bins_check.txt ${drep_dir}/drep/dereplicated_genomes ${drep_dir}/checkm
conda activate megahit
mkdir -p ${drep_dir}/drep/stats
cd ${drep_dir}/drep/dereplicated_genomes
ls bin*.fa | while read file;do
    assembly-stats -t ${file} > ${drep_dir}/drep/stats/${file}.stats.tmp
    awk -F'\t' 'NR!=1 {print $1,$2,$9,$13}' OFS='\t' ${drep_dir}/drep/stats/${file}.stats.tmp > ${drep_dir}/drep/stats/${file}.stats
done
cat ${drep_dir}/drep/stats/*.stats > ${drep_dir}/drep/stats/bin.all.stats
sed -i $'1i\Bin_ID\tSize\tN50\tN90' ${drep_dir}/drep/stats/bin.all.stats