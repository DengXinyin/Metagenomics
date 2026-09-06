#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os, argparse, shutil
import pandas as pd
from diff_method import anova, kw_wilcoxon
from get_scriptspath import scripts_path, Rscript_j


def do_anova(datadir, res_dir, tpmdir, pre_resdir):
    species = ['phylum', 'class', 'order', 'family', 'genus', 'species']
    classes = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']

    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)

        for clas in classes:

            tax_dir = os.path.join(pre_resdir, group_num, '5-TaxAnnotation', '1.Tables', 'Samples', clas)
            for specie in species:
                print("start deal %s %s data!" % (clas, specie))
                tpm_taxdir = os.path.join(tpmdir, group_num, 'anova', clas)
                if not os.path.exists(tpm_taxdir):
                    os.makedirs(tpm_taxdir)
                resdir = os.path.join(res_dir, group_num, '6-TaxStatistical_analysis', clas, specie, '1.ANOVA')
                if not os.path.exists(resdir):
                    os.makedirs(resdir)
                print("read tax_dat file", '%s/%s.xlsx' % (tax_dir, specie))
                tax_dat = pd.read_excel('%s/%s.xlsx' % (tax_dir, specie), sheet_name='relative')
                print("start anova")
                res = anova(tax_dat, sam_gro, group_num)
                print("anova over")
                if res:
                    genus_p, genus_sign_pvalue, tukey_df = res

                    # ANOVA 主结果直接输出 TSV
                    genus_p.to_csv(
                        '%s/%s_anova.tsv' % (resdir, specie),
                        sep='\t',
                        index=False,
                        encoding='utf-8'
                    )

                    # 显著结果
                    if not genus_sign_pvalue.empty:
                        genus_sign_pvalue.to_csv(
                            '%s/%s_sign.tsv' % (tpm_taxdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )
                        genus_sign_pvalue.to_csv(
                            '%s/%s_sign.tsv' % (resdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )

                    # Tukey 两两比较结果
                    if tukey_df is not None:
                        tukey_df.to_csv(
                            '%s/%s_tukey.tsv' % (tpm_taxdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )
                        tukey_df.to_csv(
                            '%s/%s_tukey.tsv' % (resdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )
                # if res:
                #     genus_p, genus_sign_pvalue, tukey_df = res
                #     with pd.ExcelWriter('%s/anova.xlsx' % resdir) as writer:
                #         genus_p.to_excel(writer, sheet_name='%s_anova' % specie, index=False)
                #         if not genus_sign_pvalue.empty:
                #             genus_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_taxdir, specie), sep='\t', index=False, encoding='utf-8')
                #             genus_sign_pvalue.to_excel(writer, sheet_name='%s_sign' % specie, index=False)
                #         if tukey_df is not None:
                #             tukey_df.to_excel(writer, sheet_name='%s_tukey' % specie, index=False)


def do_wilcoxon(datadir, tpmdir, res_dir, pre_resdir):
    species = ['phylum', 'class', 'order', 'family', 'genus', 'species']
    classes = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)

        for clas in classes:
            tax_dir = os.path.join(pre_resdir, group_num, '5-TaxAnnotation', '1.Tables', 'Samples', clas)
            for specie in species:
                print("start deal %s %s data!" % (clas, specie))
                tpm_taxdir = os.path.join(tpmdir, group_num, 'wilcoxon', clas)
                if not os.path.exists(tpm_taxdir):
                    os.makedirs(tpm_taxdir)

                resdir = os.path.join(res_dir, group_num, '6-TaxStatistical_analysis', clas, specie, '2.wilcoxon')
                if not os.path.exists(resdir):
                    os.makedirs(resdir)
                print("read tax_dat file", '%s/%s.xlsx' % (tax_dir, specie))
                tax_dat = pd.read_excel('%s/%s.xlsx' % (tax_dir, specie), sheet_name='relative')
                print("start wilcoxon")
                res = kw_wilcoxon(tax_dat, sam_gro, group_num)
                print("wilcoxon over")
                if res:
                    kww_p, kww_sign_pvalue, dunn_res = res

                    # 主检验结果直接输出 TSV
                    kww_p.to_csv(
                        '%s/%s_wilcoxon.tsv' % (resdir, specie),
                        sep='\t',
                        index=False,
                        encoding='utf-8'
                    )

                    # 显著结果
                    if not kww_sign_pvalue.empty:
                        kww_sign_pvalue.to_csv(
                            '%s/%s_sign.tsv' % (resdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )
                        kww_sign_pvalue.to_csv(
                            '%s/%s_sign.tsv' % (tpm_taxdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )

                    # Dunn 两两比较结果
                    if dunn_res is not None:
                        dunn_res.to_csv(
                            '%s/%s_dunn.tsv' % (resdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )
                        dunn_res.to_csv(
                            '%s/%s_dunn.tsv' % (tpm_taxdir, specie),
                            sep='\t',
                            index=False,
                            encoding='utf-8'
                        )
                # if res:
                #     kww_p, kww_sign_pvalue, dunn_res = res
                #     with pd.ExcelWriter('%s/wilcoxon.xlsx' % resdir) as writer:
                #         kww_p.to_excel(writer, sheet_name='%s_wilcoxon' % specie, index=False)
                #         if not kww_sign_pvalue.empty:
                #             kww_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_taxdir, specie), sep='\t', index=False,encoding='utf-8')
                #             kww_sign_pvalue.to_excel(writer, sheet_name='%s_sign' % specie, index=False)
                #         if dunn_res is not None:
                #             dunn_res.to_excel(writer, sheet_name='%s_dunn' % specie, index=False)


def plot(tpmdir, datadir, res_dir, pre_resdir):
    cmd = '''
    {0} {1}/tax_anova.R {2} {3} {4} > {2}/tax_anova.log 2>&1
    {0} {1}/tax_wilcoxon.R {2} {3} {4} > {2}/tax_wilcoxon.log 2>&1
    {0} {1}/tax_stamp.R {5} {3} {4} > {2}/tax_stamp.log 2>&1
    {0} {1}/tax_randomForest.R {5} {3} {4} > {2}/tax_randomForest.log 2>&1
    {0} {1}/tax_metaseq.R {2} {3} {4} > {2}/tax_metaseq.log 2>&1
    {0} {1}/tax_Anosim.R {5} {3} {4} > {2}/tax_Anosim.log 2>&1
    {0} {1}/tax_Adonis.R {5} {3} {4} > {2}/tax_Adonis.log 2>&1
    {0} {1}/tax_MRPP.R {5} {3} {4} > {2}/tax_MRPP.log 2>&1
    '''.format(Rscript_j, scripts_path, tpmdir, datadir, res_dir, pre_resdir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will run diff analyse')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--tpmdir', type=str, default='tax_diff', help='the tax_diff')
    parser.add_argument('--pre_resdir', type=str, default='Result', help='the resdir')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    tpmdir = os.path.abspath(args.tpmdir)
    pre_resdir = os.path.abspath(args.pre_resdir)

    do_anova(datadir, res_dir, tpmdir, pre_resdir)
    do_wilcoxon(datadir, tpmdir, res_dir, pre_resdir)
    plot(tpmdir, datadir, res_dir, pre_resdir)


if __name__ == '__main__':
    main()
