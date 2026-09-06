#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def get_table(datadir, res_dir, mobileOGdir, func_tmpdir):
    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)
        group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
        samples_ls = sam_gro.loc[:, 'sample-id'].to_list()

        resdir = os.path.join(res_dir, group_num, '12-mobileOG')
        if not os.path.exists(resdir):
            os.makedirs(resdir)
        tmpdir = os.path.join(func_tmpdir, group_num, 'mobileOG')
        if not os.path.exists(tmpdir):
            os.makedirs(tmpdir)

        gene_mobileOG_tpm = pd.read_csv('%s/mobileOG.tpm.csv' % mobileOGdir)
        selected_cols = gene_mobileOG_tpm.columns[0:11].to_list()
        gene_mobileOG_tpm = gene_mobileOG_tpm.loc[:, selected_cols + samples_ls]
        gene_mobileOG_tpm = gene_mobileOG_tpm[~(gene_mobileOG_tpm[samples_ls] == 0).all(axis=1)]
        gene_mobileOG_tpm.to_csv('%s/gene.mobileOG.tpm.csv' % resdir, index=False, encoding='utf-8-sig')

        mobileOG_anno = gene_mobileOG_tpm.iloc[:, 2:11]
        mobileOG_tpm = gene_mobileOG_tpm.iloc[:, 2:]
        mobileOG_tpm = mobileOG_tpm.groupby('mobileOG Entry Name').sum(numeric_only=True)
        mobileOG_tpm_gro = mobileOG_tpm.groupby(by=group_dic, axis=1).mean()
        mobileOG_tpm_rel = mobileOG_tpm.div(mobileOG_tpm.sum())
        mobileOG_tpm_gro_rel = mobileOG_tpm_gro.div(mobileOG_tpm_gro.sum())
        mobileOG_tpm_rel.to_csv('%s/mobileOG_diff.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
        mobileOG_tpm = pd.merge(left=mobileOG_anno, right=mobileOG_tpm, right_index=True, left_on='mobileOG Entry Name').drop_duplicates()
        mobileOG_tpm_gro = pd.merge(left=mobileOG_anno, right=mobileOG_tpm_gro, right_index=True, left_on='mobileOG Entry Name').drop_duplicates()
        mobileOG_tpm_rel = pd.merge(left=mobileOG_anno, right=mobileOG_tpm_rel, right_index=True, left_on='mobileOG Entry Name').drop_duplicates()
        mobileOG_tpm_gro_rel = pd.merge(left=mobileOG_anno, right=mobileOG_tpm_gro_rel, right_index=True, left_on='mobileOG Entry Name').drop_duplicates()

        mobileOG_cat_tpm = gene_mobileOG_tpm.loc[:, ['Major mobileOG Category'] + samples_ls]
        mobileOG_cat_tpm = mobileOG_cat_tpm.groupby('Major mobileOG Category').sum()
        mobileOG_cat_gro = mobileOG_cat_tpm.groupby(by=group_dic, axis=1).mean()
        mobileOG_cat_tpm_rel = mobileOG_cat_tpm.div(mobileOG_cat_tpm.sum())
        mobileOG_cat_gro_rel = mobileOG_cat_gro.div(mobileOG_cat_gro.sum())
        mobileOG_cat_tpm_rel.to_csv('%s/mobileOG_sam.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
        mobileOG_cat_gro_rel.to_csv('%s/mobileOG_group.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
        with pd.ExcelWriter('%s/mobileOG.xlsx' % resdir) as writer:
            mobileOG_tpm.to_excel(writer, sheet_name='samples.tpm', index=False)
            mobileOG_tpm_gro.to_excel(writer, sheet_name='group.tpm', index=False)
            mobileOG_tpm_rel.to_excel(writer, sheet_name='samples.relative', index=False)
            mobileOG_tpm_gro_rel.to_excel(writer, sheet_name='group.relative', index=False)
        with pd.ExcelWriter('%s/mobileOG.Category.xlsx' % resdir) as writer:
            mobileOG_cat_tpm.to_excel(writer, sheet_name='samples.tpm', index=True)
            mobileOG_cat_gro.to_excel(writer, sheet_name='group.tpm', index=True)
            mobileOG_cat_tpm_rel.to_excel(writer, sheet_name='samples.relative', index=True)
            mobileOG_cat_gro_rel.to_excel(writer, sheet_name='group.relative', index=True)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--mobileOGdir', type=str, default='mobileOGs', help='the res of mobileOGs')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--func_tmp', type=str, default='func_base', help='the func_base')
    args = parser.parse_args()

    mobileOGdir = os.path.abspath(args.mobileOGdir)
    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    func_tmpdir = os.path.abspath(args.func_tmp)

    # datadir = r'D:\宏基因组更新\data'
    # res_dir = r'D:\宏基因组更新\Result'
    # func_tmpdir = r'D:\宏基因组更新\func_base'
    # mobileOGdir = r'D:\宏基因组更新\mobileOGs'

    get_table(datadir, res_dir, mobileOGdir, func_tmpdir)


if __name__ == '__main__':
    main()
