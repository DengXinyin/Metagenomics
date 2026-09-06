#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024
# Optimized Version

import os
import argparse
import pandas as pd
import subprocess
from multiprocessing import Pool, cpu_count
from get_scriptspath import scripts_path, Rscript_j


# ===============================
# 全局参数
# ===============================
FUNC_INDEX = [
    '1.KEGG', '2.eggNOG', '3.CAZy', '4.GO',
    'Carbon_Cycle', 'Methane_Cycle', 'Nitrogen_Cycle',
    'phosphorylation_Cycle', 'Sulfur_Cycle',
    'ARG', 'VFDB', 'BacMet2', 'mobileOG', 'QS'
]


# ===============================
# metadata读取一次
# ===============================
def load_metadata(datadir):
    return pd.read_csv(
        '%s/sample-metadata.tsv' % datadir,
        sep='\t',
        skiprows=[1],
        dtype=str
    )


# ===============================
# 单任务运行LEfSe
# ===============================
def run_lefse(task):
    diff_dir, prefix = task

    tsv = '%s/%s.tsv' % (diff_dir, prefix)
    infile = '%s/%s.in' % (diff_dir, prefix)
    resfile = '%s/%s.res' % (diff_dir, prefix)

    # 已完成则跳过
    if os.path.exists(resfile):
        return '%s exists' % prefix

    cmd1 = [
        'lefse-format_input.py',
        tsv,
        infile,
        '-c', '1',
        '-o', '-1'
    ]

    cmd2 = [
        'run_lefse.py',
        infile,
        resfile
    ]

    try:
        subprocess.check_call(cmd1)
        subprocess.check_call(cmd2)
        return '%s done' % prefix
    except:
        return '%s failed' % prefix
def filter_taxonomy(
    tax_dat,
    abundance_cutoff=0.0001,
    prevalence_ratio=0.10,
    total_count_cutoff=1
):

    # 保存第一列名称
    id_col = tax_dat.columns[0]

    # 只取数值丰度部分
    abund_dat = tax_dat.iloc[:, 1:].copy()

    abund_dat = abund_dat.apply(
        pd.to_numeric,
        errors='coerce'
    ).fillna(0)

    raw_n = abund_dat.shape[0]

    # 相对丰度
    rel_abund = abund_dat.div(
        abund_dat.sum(axis=0),
        axis=1
    )

    # 平均相对丰度过滤
    keep1 = rel_abund.mean(axis=1) >= abundance_cutoff

    # prevalence过滤
    min_samples = max(
        1,
        int(abund_dat.shape[1] * prevalence_ratio)
    )

    keep2 = (abund_dat > 0).sum(axis=1) >= min_samples

    # 总丰度过滤
    keep3 = abund_dat.sum(axis=1) >= total_count_cutoff

    keep = keep1 & keep2 & keep3

    # 用原始表过滤
    tax_filtered = tax_dat.loc[keep].copy()

    filtered_n = tax_filtered.shape[0]
    removed_n = raw_n - filtered_n

    print("====================")
    print("raw species number:", raw_n)
    print("retained species number:", filtered_n)
    print("deleted species number:", removed_n)
    if filtered_n < 500:
        return tax_dat
    return tax_filtered
# ===============================
# LEfSe主程序（并行版）
# ===============================
def lefse(datadir, func_diffdir, func_tmpdir, threads):

    sam_gros = load_metadata(datadir)
    k = sam_gros.shape[1]

    tasks = []

    for i in range(1, k):

        group_num = 'group' + str(i)

        sam_gro = sam_gros.iloc[:, [0, i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)

        group_dic = pd.Series(
            sam_gro[group_num].values,
            index=sam_gro['sample-id']
        ).to_dict()

        for func in FUNC_INDEX:

            table_dir = os.path.join(func_tmpdir, group_num, func)
            diff_dir = os.path.join(func_diffdir, group_num, 'lefse', func)

            if not os.path.exists(table_dir):
                continue

            if not os.path.exists(diff_dir):
                os.makedirs(diff_dir)

            for file in os.listdir(table_dir):

                if not file.endswith('_diff.tsv'):
                    continue

                prefix = file.replace('_diff.tsv', '').strip()

                infile = os.path.join(table_dir, file)

                out_tsv = '%s/%s.tsv' % (diff_dir, prefix)

                # 已生成则跳过
                if not os.path.exists(out_tsv):

                    func_dat_raw = pd.read_csv(infile, sep='\t')
                    func_dat = filter_taxonomy(func_dat_raw)

                    func_dat = func_dat.rename(columns=group_dic)

                    old_name = func_dat.columns[0]

                    func_dat = func_dat.rename(
                        columns={old_name: 'group'}
                    )

                    func_dat.to_csv(
                        out_tsv,
                        sep='\t',
                        index=False,
                        encoding='utf-8-sig'
                    )

                tasks.append((diff_dir, prefix))

    # 多进程并行
    pool = Pool(threads)

    for result in pool.imap_unordered(run_lefse, tasks):
        print(result)

    pool.close()
    pool.join()


# ===============================
# 结果整理
# ===============================
def get_result_dir(res_dir, group_num, func):

    if func in ['1.KEGG', '2.eggNOG', '3.CAZy', '4.GO']:
        return os.path.join(
            res_dir, group_num,
            '8-FunctionStatistical_analysis',
            func, '9.Lefse'
        )

    elif '_Cycle' in func:
        return os.path.join(
            res_dir, group_num,
            '9-METABOLIC', func,
            '6.Statistical_test_analysis',
            '9.Lefse'
        )

    elif func == 'ARG':
        return os.path.join(
            res_dir, group_num,
            '10-ARG',
            '6.Statistical_test_analysis',
            '9.Lefse'
        )

    elif func == 'VFDB':
        return os.path.join(
            res_dir, group_num,
            '11-VFDB',
            '6.Statistical_test_analysis',
            '9.Lefse'
        )

    elif func == 'mobileOG':
        return os.path.join(
            res_dir, group_num,
            '12-mobileOG',
            '6.Statistical_test_analysis',
            '9.Lefse'
        )

    elif func == 'BacMet2':
        return os.path.join(
            res_dir, group_num,
            '13-BacMet2',
            '6.Statistical_test_analysis',
            '9.Lefse'
        )

    elif func == 'QS':
        return os.path.join(
            res_dir, group_num,
            '14-QS',
            '6.Statistical_test_analysis',
            '9.Lefse'
        )


def get_table(datadir, res_dir, func_diffdir):

    sam_gros = load_metadata(datadir)
    k = sam_gros.shape[1]

    for i in range(1, k):

        group_num = 'group' + str(i)
        print('Processing %s...' % group_num)
        for func in FUNC_INDEX:

            diff_dir = os.path.join(
                func_diffdir,
                group_num,
                'lefse',
                func
            )

            if not os.path.exists(diff_dir):
                continue

            resdir = get_result_dir(res_dir, group_num, func)

            if not os.path.exists(resdir):
                os.makedirs(resdir)

            for file in os.listdir(diff_dir):

                if not file.endswith('.res'):
                    continue

                prefix = file.replace('.res', '')

                res = pd.read_csv(
                    '%s/%s' % (diff_dir, file),
                    sep='\t',
                    header=None
                )

                res.columns = [
                    'Taxonomy',
                    'Mean',
                    'Group',
                    'LDA',
                    'Pvalue'
                ]

                res = res.dropna(subset=['Group'])

                if res.empty:
                    continue

                res.to_csv(
                    '%s/%s_LDA.tsv' % (diff_dir, prefix),
                    sep='\t',
                    index=False,
                    encoding='utf-8-sig'
                )

                res.to_excel(
                    '%s/%s_LDA.xlsx' % (resdir, prefix),
                    index=False,
                    sheet_name='LDA_score'
                )
            print('Finished processing %s...' % group_num)

# ===============================
# 绘图
# ===============================
def plot_lefse(func_diff, datadir, res_dir):

    cmd = '%s %s/func_lefse.R %s %s %s' % (
        Rscript_j,
        scripts_path,
        func_diff,
        datadir,
        res_dir
    )

    os.system(cmd)


# ===============================
# main
# ===============================
def main():

    parser = argparse.ArgumentParser()

    parser.add_argument('-I', '--i_datadir', required=True)
    parser.add_argument('--resdir', default='Result')
    parser.add_argument('--func_tmp', default='func_base')
    parser.add_argument('--func_diff', default='func_diff')

    parser.add_argument(
        '-t',
        '--threads',
        type=int,
        default=max(cpu_count()-1, 1)
    )

    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    func_tmpdir = os.path.abspath(args.func_tmp)
    func_diff = os.path.abspath(args.func_diff)

    print('Running LEfSe with %s threads...' % args.threads)

    lefse(datadir, func_diff, func_tmpdir, args.threads)

    get_table(datadir, res_dir, func_diff)

    plot_lefse(func_diff, datadir, res_dir)


if __name__ == '__main__':
    main()