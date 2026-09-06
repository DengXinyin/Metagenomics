#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def diamond(dbdir, prodigal_dir, megan_dir, anno_dir):
    cmd = '''
mkdir {3}/tmp
file_size=$(du -b {1}/unique_gene.fasta | awk '{{print $1}}')
if [ "$file_size" -gt 16106127360 ]; then
    echo "File is larger than 15GB, performing fast operation..."
    diamond blastx --threads 60 --fast --log --tmpdir {3}/tmp --db {0}/metage2 -q {1}/unique_gene.fasta \
    --max-target-seqs 10 --evalue 1e-5 -o {1}/unique.daa --outfmt 100
else
    echo "File is smaller than 15GB, performing default operation..."
    diamond blastx --threads 60 --log --tmpdir {3}/tmp --db {0}/metage2 -q {1}/unique_gene.fasta \
    --max-target-seqs 10 --evalue 1e-5 -o {1}/unique.daa --outfmt 100
fi

# diamond blastx --threads 50 --db {0}/metage -q {1}/unique_gene.fasta \
# --evalue 1e-5 -o {1}/unique.daa --outfmt 100

# megan-map-Feb2022.db
{2}/tools/daa2rma -i {1}/unique.daa \
-ms 50 -me 1.0E-7 -top 50 --minSupport 1 --minPercentIdentity 70 \
--lcaCoveragePercent 51 --threads 60 -mdb {0}/megan-nr-r1.mdb -o {1}/unique.rma

{2}/tools/rma2info -i {1}/unique.rma \
-r2c Taxonomy -v >  {3}/Tax_id.tmp.txt
sed -i '1i\GeneID\ttaxid' {3}/Tax_id.tmp.txt
'''.format(dbdir, prodigal_dir, megan_dir, anno_dir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database/NR', help='the dir of database')
    parser.add_argument('--megandir', type=str, default='/data/data1/wangli/soft/megan', help='the dir of megan')
    args = parser.parse_args()

    prodigal_dir = os.path.abspath(args.prodigal)
    anno_dir = os.path.abspath(args.Annotation)
    dbdir = os.path.abspath(args.dbdir)
    megandir = os.path.abspath(args.megandir)
    if not os.path.exists(anno_dir):
        os.mkdir(anno_dir)

    diamond(dbdir, prodigal_dir, megandir, anno_dir)


if __name__ == '__main__':
    main()
