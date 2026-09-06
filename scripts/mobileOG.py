#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def mobileOG(dbdir, prodigal_dir, mobileOGdir):
    cmd = '''
diamond blastx --threads 30 --db {0}/mobileOG/mobileOG_beatrix-1.6 -e 1e-5 \
--query {1}/unique_gene.fasta --out {2}/mobileOG_anno.txt
sed -i '1i\qseqid\tsseqid\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbiotscore' {2}/mobileOG_anno.txt
'''.format(dbdir, prodigal_dir, mobileOGdir)
    os.system(cmd)


def get_mobileOGtable(dbdir, mobileOGdir, anno_dir, bowtie):
    # mobileOGs
    mobileOG_map = pd.read_csv('%s/mobileOG/mobileOG-db-beatrix-1.6-All.csv' % dbdir, sep=',')
    gene_tax = pd.read_csv('%s/gene.taxonomy.csv' % anno_dir, index_col=0)
    gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
    gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
    gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]

    mobileOGs = pd.read_csv('%s/mobileOG_anno.txt' % mobileOGdir, sep='\t')
    mobileOGs = mobileOGs.loc[:, ['qseqid', 'sseqid', 'evalue']]
    mobileOGs = mobileOGs.loc[mobileOGs.groupby('qseqid')['evalue'].idxmin()]
    mobileOG_ano = pd.merge(left=mobileOGs, right=mobileOG_map, left_on='sseqid', right_on='mobileOG fasta Header')
    mobileOG_ano = mobileOG_ano.loc[:, ['qseqid', 'mobileOG Entry Name', 'Best Hit ID', 'mobileOG Cluster', 'Name',
    'Manual Annotation', 'Major mobileOG Category', 'Minor mobileOG Categories', 'Reference(s)', 'Evidence']]
    mobileOG_ano = mobileOG_ano.rename(columns={'qseqid': 'GeneID'})
    mobileOG_ano = pd.merge(left=gene_tax, right=mobileOG_ano, on='GeneID')

    # 丰度表
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie)
    gene_mobileOG_tpm = pd.merge(left=mobileOG_ano, right=gene_tpm, on='GeneID')
    gene_mobileOG_tpm.to_csv('%s/mobileOG.tpm.csv' % mobileOGdir, index=False, encoding='utf-8-sig')


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--mobileOGdir', type=str, default='mobileOGs', help='the res of mobileOGs')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='the dir of database')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    prodigal_dir = os.path.abspath(args.prodigal)
    mobileOGdir = os.path.abspath(args.mobileOGdir)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)

    # anno_dir = r'D:\宏基因组更新\Annotation'
    # prodigal_dir = r'D:\宏基因组更新\prodigal'
    # mobileOGdir = r'D:\宏基因组更新\mobileOGs'
    # dbdir = r'D:\宏基因组更新\database'
    # bowtie = r'D:\宏基因组更新\bowtie'

    if not os.path.exists(mobileOGdir):
        os.mkdir(mobileOGdir)

    mobileOG(dbdir, prodigal_dir, mobileOGdir)
    get_mobileOGtable(dbdir, mobileOGdir, anno_dir, bowtie)


if __name__ == '__main__':
    main()
