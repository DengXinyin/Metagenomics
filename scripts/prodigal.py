#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2023

import os
import argparse

def prodigal(megahit_dir, prodigal_dir):
    cmd = '''
parallel -j 5 --memfree 50G --xapply \
    'prodigal -i {1}/final.contigs.fa -f gff \
    -o %s/{1/}.gff3 -d %s/{1/}.fastq -a %s/{1/}.faa -p meta -q' \
    :::: %s/sample.name.txt
''' % (prodigal_dir, prodigal_dir, prodigal_dir, megahit_dir)
    os.system(cmd)

# 速度太慢
# def cdhit(prodigal_dir, cdhitdir):
# 	cmd = '''
# cat {0}/*.fastq > {0}/all.fa
# {1}/cd-hit-est -i {0}/all.fa -o {0}/unique_gene.fasta -T 72 -M 6000000 -c 0.95  -n 9 -d 0 -aS 0.9 -g 1 -sc 1 -sf 1
# seqkit fx2tab -j 36 -l -n -i -H {0}/unique_gene.fasta  > {0}/unique_length.txt
# assembly-stats -t {0}/unique_gene.fasta > {0}/unique_stats.txt
# '''.format(prodigal_dir, cdhitdir)
# 	os.system(cmd)


def mmseqs(prodigal_dir):
    cmd = '''
cat {0}/*.fastq > {0}/all.fa
file_size=$(du -b {0}/all.fa | awk '{{print $1}}')
if [ "$file_size" -gt 21474836480 ]; then
    echo "File is larger than 20GB, performing linclust operation..."
    mmseqs easy-linclust {0}/all.fa {0}/clusterRes {0}/tmp --kmer-per-seq-scale 0.3 --min-seq-id 0.95 -c 0.9 --cov-mode 1 --cluster-mode 2 --threads 60
else
    echo "File is smaller than 20GB, performing cluster operation..."
    mmseqs easy-cluster {0}/all.fa {0}/clusterRes {0}/tmp --min-seq-id 0.95 -c 0.9 --cov-mode 1 --cluster-mode 2 --threads 60
fi
cp {0}/clusterRes_rep_seq.fasta {0}/unique_gene.fasta
seqkit fx2tab -j 36 -l -n -i -H {0}/unique_gene.fasta  > {0}/unique_length.txt
assembly-stats -t {0}/unique_gene.fasta > {0}/unique_stats.txt
'''.format(prodigal_dir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will predict CDS through prodigal')
    parser.add_argument('--megahit', type=str, default='megahit', help='the res of megahit')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--cdhitdir', type=str, default='/data/data1/wangli/soft/cdhit-4.8.1',
                        help='the res of prodigal')
    args = parser.parse_args()

    megahit_dir = os.path.abspath(args.megahit)
    prodigal_dir = os.path.abspath(args.prodigal)
    cdhitdir = os.path.abspath(args.cdhitdir)
    if not os.path.exists(prodigal_dir):
        os.mkdir(prodigal_dir)

    prodigal(megahit_dir, prodigal_dir)
    # cdhit(prodigal_dir, cdhitdir)
    mmseqs(prodigal_dir)


if __name__ == '__main__':
    main()
