#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd
import re


def extract_id(sseqid):
    gi_match = re.search(r'gi\|(\d+)\|', sseqid)
    if gi_match:
        return gi_match.group(1)
    bac_match = re.search(r'(BAC\w+)\|', sseqid)
    if bac_match:
        return bac_match.group(1)
    return None


def BacMet2(dbdir, prodigal_dir, BacMet2dir):
    cmd = '''
diamond blastx --threads 30 --db {0}/BacMet/BacMet2 -e 1e-5 \
--query {1}/unique_gene.fasta --out {2}/BacMet_anno.txt
sed -i '1i\qseqid\tsseqid\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbiotscore' {2}/BacMet_anno.txt
'''.format(dbdir, prodigal_dir, BacMet2dir)
    os.system(cmd)


def get_BacMet2table(dbdir, BacMet2dir, anno_dir, bowtie):
    # BacMet2
    BacMet2_map = pd.read_csv('%s/BacMet/BacMet2_all.mapping.txt' % dbdir, sep='\t')
    gene_tax = pd.read_csv('%s/gene.taxonomy.csv' % anno_dir, index_col=0)
    gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
    gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
    gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]

    BacMet2 = pd.read_csv('%s/BacMet_anno.txt' % BacMet2dir, sep='\t')
    BacMet2 = BacMet2.loc[:, ['qseqid', 'sseqid', 'evalue']]
    BacMet2 = BacMet2.loc[BacMet2.groupby('qseqid')['evalue'].idxmin()]
    BacMet2['ID'] = BacMet2['sseqid'].apply(extract_id)
    BacMet2_ano = pd.merge(left=BacMet2, right=BacMet2_map, left_on='ID', right_on='ID')
    BacMet2_ano = BacMet2_ano.loc[:, ['qseqid', 'Gene_name', 'Accession/GenBank_ID', 'Compound', 'Source', 'NCBI_annotation']]
    BacMet2_ano = BacMet2_ano.rename(columns={'qseqid': 'GeneID'})
    BacMet2_ano = pd.merge(left=gene_tax, right=BacMet2_ano, on='GeneID')

    # 丰度表
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie)
    gene_BacMet2_tpm = pd.merge(left=BacMet2_ano, right=gene_tpm, on='GeneID')
    gene_BacMet2_tpm.to_csv('%s/BacMet2.tpm.csv' % BacMet2dir, index=False, encoding='utf-8-sig')


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--BacMet2dir', type=str, default='BacMet2', help='the res of BacMet2')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='the dir of database')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    prodigal_dir = os.path.abspath(args.prodigal)
    BacMet2dir = os.path.abspath(args.BacMet2dir)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)

    # anno_dir = r'D:\宏基因组更新\Annotation'
    # prodigal_dir = r'D:\宏基因组更新\prodigal'
    # BacMet2dir = r'D:\宏基因组更新\BacMet2'
    # dbdir = r'D:\宏基因组更新\database'
    # bowtie = r'D:\宏基因组更新\bowtie'

    if not os.path.exists(BacMet2dir):
        os.mkdir(BacMet2dir)

    BacMet2(dbdir, prodigal_dir, BacMet2dir)
    get_BacMet2table(dbdir, BacMet2dir, anno_dir, bowtie)


if __name__ == '__main__':
    main()
