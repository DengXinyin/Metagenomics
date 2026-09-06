#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def get_class_exp(bacteria_tpm, bacteria_rel, tax_dir):
    for i in range(1, 8):
        name = bacteria_tpm.columns[i]
        bacta_tax_tpm = bacteria_tpm.iloc[:, [i] + list(range(8, len(bacteria_tpm.columns)))]
        bacta_tax_tpm = bacta_tax_tpm.groupby(by=name).sum()
        bacta_tax_rela = bacteria_rel.iloc[:, [i] + list(range(8, len(bacteria_rel.columns)))]
        bacta_tax_rela = bacta_tax_rela.groupby(by=name).sum()
        with pd.ExcelWriter('%s/%s.xlsx' % (tax_dir, name)) as writer:
            bacta_tax_tpm.to_excel(writer, sheet_name='tpm', index=True)
            bacta_tax_rela.to_excel(writer, sheet_name='relative', index=True)


def tax_table(anno_dir, dbdir, bowtie, tax_anno):
    taxid = pd.read_csv('%s/Tax_id.tmp.txt' % tax_anno, sep='\t')
    tax_ano = pd.read_csv('%s/metage.taxonomy.txt' % dbdir, sep='\t')
    gene2tax = pd.merge(left=taxid, right=tax_ano, on='taxid')
    gene2tax = gene2tax.drop(['taxid'], axis=1)
    gene2tax.to_csv('%s/gene.taxonomy.csv' % anno_dir, index=False, encoding='utf-8-sig')

    tax_cla = ['All', 'bacteria', 'Archaea', 'Fungi', 'Virus']
    for cla in tax_cla:
        tax_dir = os.path.join(anno_dir, cla)
        if not os.path.exists(tax_dir):
            os.mkdir(tax_dir)

    # 所有级别
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie, index_col=0)
    all_tpm = pd.merge(left=gene2tax, right=gene_tpm, on='GeneID')
    all_rel = all_tpm.iloc[:, 8:].div(all_tpm.iloc[:, 8:].sum())
    all_rel = pd.concat([all_tpm.iloc[:, 0: 8], all_rel], axis=1)
    all_tpm.to_csv('%s/All/All.taxonomy.csv' % anno_dir, index=False, encoding='utf-8-sig')
    all_rel.to_csv('%s/All/All.taxonomy.rel.csv' % anno_dir, index=False, encoding='utf-8-sig')


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database/NR', help='the dir of database')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    parser.add_argument('--tax_anno', type=str, default='Annotation', help='the res of bowtie')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)
    tax_anno = os.path.abspath(args.tax_anno)
    if not os.path.exists(anno_dir):
        os.mkdir(anno_dir)

    tax_table(anno_dir, dbdir, bowtie, tax_anno)


if __name__ == '__main__':
    main()
