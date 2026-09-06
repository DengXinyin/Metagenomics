#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def get_table(datadir, res_dir, BacMet2dir, func_tmpdir):
    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)
        group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
        samples_ls = sam_gro.loc[:, 'sample-id'].to_list()

        resdir = os.path.join(res_dir, group_num, '13-BacMet2')
        if not os.path.exists(resdir):
            os.makedirs(resdir)
        tmpdir = os.path.join(func_tmpdir, group_num, 'BacMet2')
        if not os.path.exists(tmpdir):
            os.makedirs(tmpdir)

        gene_BacMet2_tpm = pd.read_csv('%s/BacMet2.tpm.csv' % BacMet2dir)
        selected_cols = gene_BacMet2_tpm.columns[0:7].to_list()
        gene_BacMet2_tpm = gene_BacMet2_tpm.loc[:, selected_cols + samples_ls]
        gene_BacMet2_tpm = gene_BacMet2_tpm[~(gene_BacMet2_tpm[samples_ls] == 0).all(axis=1)]
        gene_BacMet2_tpm.to_csv('%s/gene.BacMet2.tpm.csv' % resdir, index=False, encoding='utf-8-sig')

        BacMet2_anno = gene_BacMet2_tpm.iloc[:, [2] + list(range(4, 6))]
        BacMet2_tpm = gene_BacMet2_tpm.groupby('Gene_name').sum(numeric_only=True)
        BacMet2_tpm_gro = BacMet2_tpm.groupby(by=group_dic, axis=1).mean()
        BacMet2_tpm_rel = BacMet2_tpm.div(BacMet2_tpm.sum())
        BacMet2_tpm_gro_rel = BacMet2_tpm_gro.div(BacMet2_tpm_gro.sum())
        BacMet2_tpm_rel.to_csv('%s/BacMet2_diff.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
        BacMet2_tpm_rel.to_csv('%s/BacMet2_sam.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
        BacMet2_tpm_gro_rel.to_csv('%s/BacMet2_group.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
        BacMet2_tpm = pd.merge(left=BacMet2_anno, right=BacMet2_tpm, right_index=True, left_on='Gene_name').drop_duplicates()
        BacMet2_tpm_gro = pd.merge(left=BacMet2_anno, right=BacMet2_tpm_gro, right_index=True, left_on='Gene_name').drop_duplicates()
        BacMet2_tpm_rel = pd.merge(left=BacMet2_anno, right=BacMet2_tpm_rel, right_index=True, left_on='Gene_name').drop_duplicates()
        BacMet2_tpm_gro_rel = pd.merge(left=BacMet2_anno, right=BacMet2_tpm_gro_rel, right_index=True, left_on='Gene_name').drop_duplicates()

        with pd.ExcelWriter('%s/BacMet2.xlsx' % resdir) as writer:
            BacMet2_tpm.to_excel(writer, sheet_name='samples.tpm', index=False)
            BacMet2_tpm_gro.to_excel(writer, sheet_name='group.tpm', index=False)
            BacMet2_tpm_rel.to_excel(writer, sheet_name='samples.relative', index=False)
            BacMet2_tpm_gro_rel.to_excel(writer, sheet_name='group.relative', index=False)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--BacMet2dir', type=str, default='BacMet2', help='the res of BacMet2')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--func_tmp', type=str, default='func_base', help='the func_base')
    args = parser.parse_args()

    BacMet2dir = os.path.abspath(args.BacMet2dir)
    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    func_tmpdir = os.path.abspath(args.func_tmp)

    # datadir = r'D:\宏基因组更新\data'
    # res_dir = r'D:\宏基因组更新\Result'
    # func_tmpdir = r'D:\宏基因组更新\func_base'
    # BacMet2dir = r'D:\宏基因组更新\BacMet2'

    get_table(datadir, res_dir, BacMet2dir, func_tmpdir)


if __name__ == '__main__':
    main()