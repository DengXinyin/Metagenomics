#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd
from diff_method import anova, kw_wilcoxon
from get_scriptspath import scripts_path, Rscript_j


def do_anova(datadir, func_diffdir, res_dir, func_tmpdir):
    func_index = ['1.KEGG', '2.eggNOG', '3.CAZy', '4.GO','Carbon_Cycle',
                'Methane_Cycle', 'Nitrogen_Cycle', 'phosphorylation_Cycle',
                'Sulfur_Cycle', 'ARG', 'VFDB', 'BacMet2', 'mobileOG', 'QS']

    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)

        for func in func_index:
            tpm_diffdir = os.path.join(func_diffdir, group_num, 'anova', func)
            if not os.path.exists(tpm_diffdir):
                os.makedirs(tpm_diffdir)
            if func == '1.KEGG' or func == '2.eggNOG' or func == '3.CAZy' or func == '4.GO':
                resdir = os.path.join(res_dir, group_num, '8-FunctionStatistical_analysis', func, '1.ANOVA')
            elif '_Cycle' in func:
                resdir = os.path.join(res_dir, group_num, '9-METABOLIC', func, '6.Statistical_test_analysis', '1.ANOVA')
            elif func == 'ARG':
                resdir = os.path.join(res_dir, group_num, '10-ARG', '6.Statistical_test_analysis', '1.ANOVA')
            elif func == 'VFDB':
                resdir = os.path.join(res_dir, group_num, '11-VFDB', '6.Statistical_test_analysis', '1.ANOVA')
            elif func == 'mobileOG':
                resdir = os.path.join(res_dir, group_num, '12-mobileOG', '6.Statistical_test_analysis', '1.ANOVA')
            elif func == 'BacMet2':
                resdir = os.path.join(res_dir, group_num, '13-BacMet2', '6.Statistical_test_analysis', '1.ANOVA')
            elif func == 'QS':
                resdir = os.path.join(res_dir, group_num, '14-QS', '6.Statistical_test_analysis', '1.ANOVA')
            if not os.path.exists(resdir):
                os.makedirs(resdir)
            print("start deal %s data!" % func)
            table_dir = os.path.join(func_tmpdir, group_num, func)
            files = os.listdir(table_dir)
            for file in files:
                if file.endswith('_diff.tsv'):
                    prefix = file.split('_diff.tsv')[0]
                    print("read func_dat file", '%s/%s' % (table_dir, file))
                    func_dat = pd.read_csv('%s/%s' % (table_dir, file), sep='\t')
                    print("read over ")
                    print("start anova")
                    res = anova(func_dat, sam_gro, group_num)
                    print("anova over")

                    # if res:
                    #     genus_p, genus_sign_pvalue, tukey_df = res
                    #     with pd.ExcelWriter('%s/%s_anova.xlsx' % (resdir, prefix)) as writer:
                    #         genus_p.to_excel(writer, sheet_name='anova', index=False)
                    #         if not genus_sign_pvalue.empty:
                    #             genus_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_diffdir, prefix), sep='\t', index=False, encoding='utf-8-sig')
                    #             genus_sign_pvalue.to_excel(writer, sheet_name='sign', index=False)
                    #         if tukey_df is not None:
                    #             tukey_df.to_csv('%s/%s_anova.csv' % (resdir, prefix),index=False, encoding="utf-8-sig")
                                # tukey_df.to_excel(writer, sheet_name='tukey', index=False)
                    if res:
                        genus_p, genus_sign_pvalue, tukey_df = res

                        # 直接输出 txt 文件，不再写 Excel
                        print("out all results")
                        genus_p.to_csv(
                            '%s/%s_anova.tsv' % (resdir, prefix),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )

                        # 显著结果
                        if not genus_sign_pvalue.empty:
                            print("out significant results")
                            genus_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_diffdir, prefix), sep='\t', index=False, encoding='utf-8-sig')
                            genus_sign_pvalue.to_csv(
                                '%s/%s_sign.tsv' % (resdir, prefix),
                                sep='\t',
                                index=False,
                                encoding='utf-8'
                            )

                        # Tukey结果
                        if tukey_df is not None:
                            tukey_df.to_csv(
                                '%s/%s_tukey.tsv' % (tpm_diffdir, prefix),
                                sep='\t',
                                index=False,
                                encoding='utf-8'
                            )
                            print("out tukey results")
                            tukey_df.to_csv(
                                '%s/%s_tukey.tsv' % (resdir, prefix),
                                sep='\t',
                                index=False,
                                encoding='utf-8'
                            )
def do_wilcoxon(datadir, func_diffdir, res_dir, func_tmpdir):
    func_index = ['1.KEGG', '2.eggNOG', '3.CAZy', '4.GO','Carbon_Cycle',
                'Methane_Cycle', 'Nitrogen_Cycle', 'phosphorylation_Cycle',
                'Sulfur_Cycle', 'ARG', 'VFDB', 'BacMet2', 'mobileOG', 'QS']

    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)

        for func in func_index:
            tpm_diffdir = os.path.join(func_diffdir, group_num, 'wilcoxon', func)
            if not os.path.exists(tpm_diffdir):
                os.makedirs(tpm_diffdir)
            if func == '1.KEGG' or func == '2.eggNOG' or func == '3.CAZy' or func == '4.GO':
                resdir = os.path.join(res_dir, group_num, '8-FunctionStatistical_analysis', func, '2.wilcoxon')
            elif '_Cycle' in func:
                resdir = os.path.join(res_dir, group_num, '9-METABOLIC', func, '6.Statistical_test_analysis',
                                    '2.wilcoxon')
            elif func == 'ARG':
                resdir = os.path.join(res_dir, group_num, '10-ARG', '6.Statistical_test_analysis', '2.wilcoxon')
            elif func == 'VFDB':
                resdir = os.path.join(res_dir, group_num, '11-VFDB', '6.Statistical_test_analysis', '2.wilcoxon')
            elif func == 'mobileOG':
                resdir = os.path.join(res_dir, group_num, '12-mobileOG', '6.Statistical_test_analysis', '2.wilcoxon')
            elif func == 'BacMet2':
                resdir = os.path.join(res_dir, group_num, '13-BacMet2', '6.Statistical_test_analysis', '2.wilcoxon')
            elif func == 'QS':
                resdir = os.path.join(res_dir, group_num, '14-QS', '6.Statistical_test_analysis', '2.wilcoxon')
            if not os.path.exists(resdir):
                os.makedirs(resdir)

            table_dir = os.path.join(func_tmpdir, group_num, func)
            files = os.listdir(table_dir)
            for file in files:
                if file.endswith('_diff.tsv'):
                    prefix = file.split('_diff.tsv')[0]
                    func_dat = pd.read_csv('%s/%s' % (table_dir, file), sep='\t')
                    res = kw_wilcoxon(func_dat, sam_gro, group_num)
                    if res:
                        kww_p, kww_sign_pvalue, dunn_res = res

                        # 主检验结果直接输出 TSV
                        kww_p.to_csv(
                            '%s/%s_wilcoxon.tsv' % (resdir, prefix),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )

                        # 显著结果
                        if not kww_sign_pvalue.empty:
                            kww_sign_pvalue.to_csv(
                                '%s/%s_sign.tsv' % (resdir, prefix),
                                sep='\t',
                                index=False,
                                encoding='utf-8'
                            )
                            kww_sign_pvalue.to_csv(
                                '%s/%s_sign.tsv' % (tpm_diffdir, prefix),
                                sep='\t',
                                index=False,
                                encoding='utf-8'
                            )

                        # Dunn 两两比较结果
                        if dunn_res is not None:
                            dunn_res.to_csv(
                                '%s/%s_dunn.tsv' % (resdir, prefix),
                                sep='\t',
                                index=False,
                                encoding='utf-8'
                            )

                            dunn_res.to_csv(
                                '%s/%s_dunn.tsv' % (tpm_diffdir, prefix),
                                sep='\t',
                                index=False,
                                encoding='utf-8'
                            )

def plot(func_diff, datadir, res_dir, func_tmpdir):
    cmd = '''
        {0} {1}/func_anova.R {2} {3} {4} > {2}/func_anova.log 2>&1
        {0} {1}/func_wilcoxon.R {2} {3} {4} > {2}/func_wilcoxon.log 2>&1
        {0} {1}/func_stamp.R {5} {3} {4} > {2}/func_stamp.log 2>&1
        {0} {1}/func_randomForest.R {5} {3} {4} > {2}/func_randomForest.log 2>&1
        {0} {1}/func_metaseq.R {5} {3} {4} > {2}/func_metaseq.log 2>&1
        {0} {1}/func_Anosim.R {5} {3} {4} > {2}/func_Anosim.log 2>&1
        {0} {1}/func_Adonis.R {5} {3} {4} > {2}/func_Adonis.log 2>&1
        {0} {1}/func_MRPP.R {5} {3} {4} > {2}/func_MRPP.log 2>&1
        '''.format(Rscript_j, scripts_path, func_diff, datadir, res_dir, func_tmpdir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--func_tmp', type=str, default='func_base', help='the func_base')
    parser.add_argument('--func_diff', type=str, default='func_diff', help='the func_diff')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    func_tmpdir = os.path.abspath(args.func_tmp)
    func_diff = os.path.abspath(args.func_diff)

    do_anova(datadir, func_diff, res_dir, func_tmpdir)
    do_wilcoxon(datadir, func_diff, res_dir, func_tmpdir)
    plot(func_diff, datadir, res_dir, func_tmpdir)


if __name__ == '__main__':
    main()
