#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def get_Cyctable(anno_dir, bowtie, CycDB_dir, dbdir):
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie)
    gene_tax = pd.read_csv('%s/gene.taxonomy.csv' % anno_dir, index_col=0)
    gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
    gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
    gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]

    # CycDB
    CycDB_f = ['Carbon', 'Methane', 'Nitrogen', 'phosphorylation', 'Sulfur']
    for Cyc in CycDB_f:
        Cyc_map = pd.read_csv('%s/diting/%s.txt' % (dbdir, Cyc), sep='\t')
        gene_ko = pd.read_csv('%s/KEGG/KEGG.tpm.csv' % anno_dir)
        gene_ko = gene_ko.iloc[:, 0:2]
        Cyc_anno = pd.merge(left=gene_ko, right=Cyc_map, on='KO')
        Cyc_anno = pd.merge(left=gene_tax, right=Cyc_anno, on='GeneID')

        # 丰度表
        Cyc_tpm = pd.merge(left=Cyc_anno, right=gene_tpm, on='GeneID')
        Cyc_tpm = Cyc_tpm.drop(['Cycle'], axis=1)
        Cyc_tpm = Cyc_tpm.drop_duplicates()
        if (Cyc_tpm.shape[0] == 0):
            continue
        Cyc_tpm.to_excel('%s/%s_Cycle.xlsx' % (CycDB_dir, Cyc), index=False)

        k = Cyc_tpm.shape[1]
        Cyc_pathway = Cyc_tpm.iloc[:, [3] + list(range(5, k))]
        Cyc_pathway = Cyc_pathway.groupby('Pathway').sum()
        Cyc_pathway.to_excel('%s/%s_Cycle_pathway.xlsx' % (CycDB_dir, Cyc), index=True)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--CycDB', type=str, default='CycDB', help='the res of CycDB')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='the dir of database')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    CycDB_dir = os.path.abspath(args.CycDB)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)
    if not os.path.exists(CycDB_dir):
        os.mkdir(CycDB_dir)
    get_Cyctable(anno_dir, bowtie, CycDB_dir, dbdir)


if __name__ == '__main__':
    main()
