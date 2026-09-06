#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def get_table(datadir, res_dir, QSdir, func_tmpdir):
    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)
        group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
        samples_ls = sam_gro.loc[:, 'sample-id'].to_list()

        resdir = os.path.join(res_dir, group_num, '14-QS')
        if not os.path.exists(resdir):
            os.makedirs(resdir)
        tmpdir = os.path.join(func_tmpdir, group_num, 'QS')
        if not os.path.exists(tmpdir):
            os.makedirs(tmpdir)

        gene_qs_tpm_all = pd.read_csv('%s/QS.tpm.csv' % QSdir)
        qs_selected = gene_qs_tpm_all.columns[0:10].to_list()
        gene_qs_tpm = gene_qs_tpm_all.loc[:, qs_selected + samples_ls]
        gene_qs_tpm = gene_qs_tpm[~(gene_qs_tpm[samples_ls] == 0).all(axis=1)]
        gene_qs_tpm.to_csv('%s/gene.qs.tpm.csv' % resdir, index=False, encoding='utf-8-sig')
        qs_indexs = ['Entry', 'Protein family']
        gene_qs_tpm = gene_qs_tpm.drop(['Length'], axis=1)
        qs_anno = gene_qs_tpm.loc[:, ['Entry', 'Gene Names', 'Protein names', 'Protein family',
                                'Function [CC]' ,'Reviewed']]
        for qs_i in qs_indexs:
            qs_tpm = gene_qs_tpm.groupby(qs_i).sum(numeric_only=True)
            qs_tpm_gro = qs_tpm.groupby(by=group_dic, axis=1).mean()
            qs_tpm_rel = qs_tpm.div(qs_tpm.sum())
            qs_tpm_gro_rel = qs_tpm_gro.div(qs_tpm_gro.sum())
            if qs_i == 'Entry':
                prefix = ''
                qs_tpm_rel.to_csv('%s/qs_diff.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
                qs_tpm = pd.merge(left=qs_anno, right=qs_tpm, right_index=True, left_on='Entry').drop_duplicates()
                qs_tpm_rel = pd.merge(left=qs_anno, right=qs_tpm_rel, right_index=True, left_on='Entry').drop_duplicates()
                qs_tpm_gro = pd.merge(left=qs_anno, right=qs_tpm_gro, right_index=True, left_on='Entry').drop_duplicates()
                qs_tpm_gro_rel = pd.merge(left=qs_anno, right=qs_tpm_gro_rel, right_index=True, left_on='Entry').drop_duplicates()
                with pd.ExcelWriter('%s/qs%s.xlsx' % (resdir, prefix)) as writer:
                    qs_tpm.to_excel(writer, sheet_name='samples.tpm', index=False)
                    qs_tpm_gro.to_excel(writer, sheet_name='group.tpm', index=False)
                    qs_tpm_rel.to_excel(writer, sheet_name='samples.relative', index=False)
                    qs_tpm_gro_rel.to_excel(writer, sheet_name='group.relative', index=False)
            else:
                prefix = '.Category'
                qs_tpm_rel.to_csv('%s/qs_sam.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
                qs_tpm_gro_rel.to_csv('%s/qs_group.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
                with pd.ExcelWriter('%s/qs%s.xlsx' % (resdir, prefix)) as writer:
                    qs_tpm.to_excel(writer, sheet_name='samples.tpm', index=True)
                    qs_tpm_gro.to_excel(writer, sheet_name='group.tpm', index=True)
                    qs_tpm_rel.to_excel(writer, sheet_name='samples.relative', index=True)
                    qs_tpm_gro_rel.to_excel(writer, sheet_name='group.relative', index=True)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--QSdir', type=str, default='QS', help='the res of QSdir')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--func_tmp', type=str, default='func_base', help='the func_base')
    args = parser.parse_args()

    QSdir = os.path.abspath(args.QSdir)
    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    func_tmpdir = os.path.abspath(args.func_tmp)

    # datadir = r'D:\宏基因组更新\data'
    # res_dir = r'D:\宏基因组更新\Result'
    # func_tmpdir = r'D:\宏基因组更新\func_base'
    # QSdir = r'D:\宏基因组更新\QS'

    get_table(datadir, res_dir, QSdir, func_tmpdir)


if __name__ == '__main__':
    main()
