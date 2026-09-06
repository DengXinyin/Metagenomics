#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def vfdb(dbdir, prodigal_dir, VFDB_dir):
    cmd = '''
diamond blastx --threads 30 --db {0}/VFDB/version-2025-12/VFDB_setA -e 1e-5 \
--query {1}/unique_gene.fasta --out {2}/vf_anno.txt
sed -i '1i\qseqid\tsseqid\tpident\tlength\tmismatch\tgapopen\tqstart\tqend\tsstart\tsend\tevalue\tbiotscore' {2}/vf_anno.txt
'''.format(dbdir, prodigal_dir, VFDB_dir)
    os.system(cmd)


def get_vftable(dbdir, VFDB_dir, bowtie, anno_dir):
    VF_map = pd.read_csv('%s/VFDB/version-2025-12/VF_map.csv' % dbdir)
    fasta2VF = pd.read_csv('%s/VFDB/version-2025-12/fasta2VFID.tsv' % dbdir, sep='\t')
    gene_tax = pd.read_csv('%s/gene.taxonomy.csv' % anno_dir, index_col=0)
    gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
    gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
    gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]

    vfres = pd.read_csv('%s/vf_anno.txt' % VFDB_dir, sep='\t')
    vfres = vfres.loc[:, ['qseqid', 'sseqid', 'evalue']]
    vfres = vfres.loc[vfres.groupby('qseqid')['evalue'].idxmin()]
    vfres = pd.merge(left=vfres, right=fasta2VF, left_on='sseqid', right_on='fasta_ID')
    vf_ano = pd.merge(left=vfres, right=VF_map, on='VFID')
    vf_ano = vf_ano.loc[:, ['qseqid', 'VF_Name', 'VFcategory']]
    vf_ano = vf_ano.rename(columns={'qseqid': 'GeneID'})
    vf_ano = pd.merge(left=gene_tax, right=vf_ano, on='GeneID')

    # 丰度表
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie)
    gene_vf_tpm = pd.merge(left=vf_ano, right=gene_tpm, on='GeneID')
    gene_vf_tpm.to_csv('%s/gene.vf.tpm.csv' % VFDB_dir, index=False, encoding='utf-8-sig')

    k = gene_vf_tpm.shape[1]
    vf_tpm = gene_vf_tpm.iloc[:, [2] + list(range(4, k))]
    vf_tpm = vf_tpm.groupby('VF_Name').sum()
    vf_tpm.to_excel('%s/vf.tpm.xlsx' % VFDB_dir, index=True)

    vf_ca_tpm = gene_vf_tpm.iloc[:, 3:]
    vf_ca_tpm = vf_ca_tpm.groupby('VFcategory').sum()
    vf_ca_tpm.to_excel('%s/vf.category.tpm.xlsx' % VFDB_dir, index=True)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--VFDB', type=str, default='VFDB', help='the res of VFDB')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='the dir of database')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    prodigal_dir = os.path.abspath(args.prodigal)
    VFDB_dir = os.path.abspath(args.VFDB)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)
    if not os.path.exists(VFDB_dir):
        os.mkdir(VFDB_dir)

    vfdb(dbdir, prodigal_dir, VFDB_dir)
    get_vftable(dbdir, VFDB_dir, bowtie, anno_dir)


if __name__ == '__main__':
    main()
