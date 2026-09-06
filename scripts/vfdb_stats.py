#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def get_table(datadir, res_dir, VFDB_dir, func_tmpdir):
    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)
        group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
        samples_ls = sam_gro.loc[:, 'sample-id'].to_list()

        resdir = os.path.join(res_dir, group_num, '11-VFDB')
        if not os.path.exists(resdir):
            os.makedirs(resdir)
        tmpdir = os.path.join(func_tmpdir, group_num, 'VFDB')
        if not os.path.exists(tmpdir):
            os.makedirs(tmpdir)

        gene_vf_tpm_all = pd.read_csv('%s/gene.vf.tpm.csv' % VFDB_dir)
        vf_selected = gene_vf_tpm_all.columns[0:4].to_list()
        gene_vf_tpm = gene_vf_tpm_all.loc[:, vf_selected + samples_ls]
        gene_vf_tpm = gene_vf_tpm[~(gene_vf_tpm[samples_ls] == 0).all(axis=1)]
        gene_vf_tpm.to_csv('%s/gene.VFDB.tpm.csv' % resdir, index=False, encoding='utf-8-sig')

        vf_indexs = ['VF_Name', 'VFcategory']
        for vf_i in vf_indexs:
            vf_tpm = gene_vf_tpm.groupby(vf_i).sum(numeric_only=True)
            vf_tpm_gro = vf_tpm.groupby(by=group_dic, axis=1).mean()
            vf_tpm_rel = vf_tpm.div(vf_tpm.sum())
            vf_tpm_gro_rel = vf_tpm_gro.div(vf_tpm_gro.sum())
            if vf_i == 'VF_Name':
                prefix = ''
                vf_tpm_rel.to_csv('%s/VFDB_diff.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
            else:
                prefix = '.Category'
                vf_tpm_rel.to_csv('%s/VFDB_sam.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
                vf_tpm_gro_rel.to_csv('%s/VFDB_group.tsv' % tmpdir, sep='\t', index=True, encoding='utf-8-sig')
            with pd.ExcelWriter('%s/VFDB%s.xlsx' % (resdir, prefix)) as writer:
                vf_tpm.to_excel(writer, sheet_name='samples.tpm', index=True)
                vf_tpm_gro.to_excel(writer, sheet_name='group.tpm', index=True)
                vf_tpm_rel.to_excel(writer, sheet_name='samples.relative', index=True)
                vf_tpm_gro_rel.to_excel(writer, sheet_name='group.relative', index=True)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--VFDB', type=str, default='VFDB', help='the res of VFDB')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--func_tmp', type=str, default='func_base', help='the func_base')
    args = parser.parse_args()

    VFDB_dir = os.path.abspath(args.VFDB)
    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    func_tmpdir = os.path.abspath(args.func_tmp)

    # datadir = r'D:\宏基因组更新\data'
    # res_dir = r'D:\宏基因组更新\Result'
    # func_tmpdir = r'D:\宏基因组更新\func_base'
    # VFDB_dir = r'D:\宏基因组更新\VFDB'

    get_table(datadir, res_dir, VFDB_dir, func_tmpdir)


if __name__ == '__main__':
    main()
