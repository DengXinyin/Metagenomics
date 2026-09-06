#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def arg_soap(dbdir, prodigal_dir, ARGdir):
    cmd = '''
diamond blastx --threads 30 --db {0}/ARGs/SARG_v3.2 -e 1e-5 \
--query {1}/unique_gene.fasta --out {2}/ARGs_anno.txt
sed -i '1i\qseqid\tsseqid\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbiotscore' {2}/ARGs_anno.txt
'''.format(dbdir, prodigal_dir, ARGdir)
    os.system(cmd)


def get_argtable(dbdir, ARGdir, anno_dir, bowtie):
    # ARGs
    ARG_map = pd.read_csv('%s/ARGs/SARG_v3.2_S_database.txt' % dbdir, sep='\t')
    gene_tax = pd.read_csv('%s/gene.taxonomy.csv' % anno_dir, index_col=0)
    gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
    gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
    gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]

    ARGs = pd.read_csv('%s/ARGs_anno.txt' % ARGdir, sep='\t')
    ARGs = ARGs.loc[:, ['qseqid', 'sseqid', 'evalue']]
    ARGs = ARGs.loc[ARGs.groupby('qseqid')['evalue'].idxmin()]
    ARG_ano = pd.merge(left=ARGs, right=ARG_map, left_on='sseqid', right_on='SARG.Seq.ID')
    ARG_ano = ARG_ano.loc[:, ['qseqid', 'Type', 'ARG']]
    ARG_ano = ARG_ano.rename(columns={'qseqid': 'GeneID'})
    ARG_ano = pd.merge(left=gene_tax, right=ARG_ano, on='GeneID')

    # 丰度表
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie)
    gene_ARG_tpm = pd.merge(left=ARG_ano, right=gene_tpm, on='GeneID')
    gene_ARG_tpm.to_csv('%s/ARG.tpm.csv' % ARGdir, index=False, encoding='utf-8-sig')

    k = gene_ARG_tpm.shape[1]
    ARG_cat_tpm = gene_ARG_tpm.iloc[:, [2] + list(range(4, k))]
    ARG_cat_tpm = ARG_cat_tpm.groupby('Type').sum()
    ARG_cat_tpm.to_excel('%s/ARG.Category.tpm.xlsx' % ARGdir, index=True)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--ARGdir', type=str, default='ARGs', help='the res of VFDB')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='the dir of database')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    prodigal_dir = os.path.abspath(args.prodigal)
    ARGdir = os.path.abspath(args.ARGdir)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)
    if not os.path.exists(ARGdir):
        os.mkdir(ARGdir)

    arg_soap(dbdir, prodigal_dir, ARGdir)
    get_argtable(dbdir, ARGdir, anno_dir, bowtie)


if __name__ == '__main__':
    main()
