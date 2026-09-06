#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def eggNOG_mapper(emapperdir, prodigal_dir, dbdir, anno_dir):
    cmd = '''
file_size=$(du -b {1}/unique_gene.fasta | awk '{{print $1}}')
if [ "$file_size" -gt 16106127360 ]; then
    echo "File is larger than 15GB, performing fast operation..."
    python {0}/emapper.py --cpu 50 -i {1}/unique_gene.fasta \
    --itype CDS -m diamond --evalue 1e-5 --sensmode fast --dmnd_iterate no \
    --data_dir {2}/eggNOG -o func --output_dir {1}
else
    echo "File is smaller than 15GB, performing mid-sensitive operation..."
    python {0}/emapper.py --cpu 50 -i {1}/unique_gene.fasta \
    --itype CDS -m diamond --evalue 1e-5 --sensmode mid-sensitive \
    --data_dir {2}/eggNOG -o func --output_dir {1}
fi

sed '1,4d' {1}/func.emapper.annotations > {3}/func.emapper.annotations
num=$(wc -l {3}/func.emapper.annotations | cut -d ' ' -f 1)
start=$[$num-2]
sed -i "${{start}},${{num}}d" {3}/func.emapper.annotations
'''.format(emapperdir, prodigal_dir, dbdir, anno_dir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='the dir of database')
    parser.add_argument('--emapperdir', type=str, default='/home/wangli/soft/eggnog-mapper', help='the dir of megan')
    args = parser.parse_args()

    prodigal_dir = os.path.abspath(args.prodigal)
    anno_dir = os.path.abspath(args.Annotation)
    dbdir = os.path.abspath(args.dbdir)
    emapperdir = os.path.abspath(args.emapperdir)
    if not os.path.exists(anno_dir):
        os.mkdir(anno_dir)

    # bowtie = r'D:\宏基因组更新\bowtie'
    # anno_dir = r'D:\宏基因组更新\Annotation'
    # mapdir = r'D:\宏基因组更新\database'
    # dbdir = r'D:\宏基因组更新\database'

    eggNOG_mapper(emapperdir, prodigal_dir, dbdir, anno_dir)

if __name__ == '__main__':
    main()
