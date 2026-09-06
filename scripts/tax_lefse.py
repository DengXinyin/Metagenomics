#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024
# Optimized LEfSe Taxonomy Version

import os
import argparse
import pandas as pd
import subprocess
from multiprocessing import Pool, cpu_count
from get_scriptspath import scripts_path, Rscript_j


# ===============================
# 常量
# ===============================
CLASSES = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
SPECIES = ['phylum', 'class', 'order', 'family', 'genus', 'species']


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

    tpm_dir, specie = task

    tsv = '%s/%s.tsv' % (tpm_dir, specie)
    infile = '%s/%s.in' % (tpm_dir, specie)
    resfile = '%s/%s.res' % (tpm_dir, specie)

    if os.path.exists(resfile):
        return '%s exists' % specie

    cmd1 = [
        'lefse-format_input.py',
        tsv,
        infile,
        '-c', '1',
        '-o', '1000000'
    ]

    cmd2 = [
        'run_lefse.py',
        infile,
        resfile
    ]

    try:
        subprocess.check_call(cmd1)
        subprocess.check_call(cmd2)
        return '%s done' % specie
    except:
        return '%s failed' % specie


#########################################################

#########################################################

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
#
# ===============================
def lefse(datadir, tpmdir, pre_resdir, threads):

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

        for clas in CLASSES:

            tax_dir = os.path.join(
                pre_resdir,
                group_num,
                '5-TaxAnnotation',
                '1.Tables',
                'Samples',
                clas
            )

            tpm_dir = os.path.join(
                tpmdir,
                group_num,
                'lefse',
                clas
            )

            if not os.path.exists(tpm_dir):
                os.makedirs(tpm_dir)

            for specie in SPECIES:

                infile = '%s/%s.xlsx' % (tax_dir, specie)

                if not os.path.exists(infile):
                    continue

                out_tsv = '%s/%s.tsv' % (tpm_dir, specie)

                if not os.path.exists(out_tsv):

                    tax_dat_raw = pd.read_excel(
                        infile,
                        sheet_name='tpm'
                    )
                    tax_dat = filter_taxonomy(tax_dat_raw)
                    tax_dat = tax_dat.rename(columns=group_dic)

                    tax_dat = tax_dat.rename(
                        columns={specie: 'group'}
                    )

                    tax_dat.to_csv(
                        out_tsv,
                        sep='\t',
                        index=False,
                        encoding='utf-8-sig'
                    )

                tasks.append((tpm_dir, specie))

    pool = Pool(threads)

    for result in pool.imap_unordered(run_lefse, tasks):
        print(result)

    pool.close()
    pool.join()


# ===============================
# 结果整理
# ===============================
def get_table(datadir, tpmdir, res_dir):

    sam_gros = load_metadata(datadir)
    k = sam_gros.shape[1]

    for i in range(1, k):

        group_num = 'group' + str(i)
        print('Processing %s...' % group_num)
        for clas in CLASSES:

            tpm_dir = os.path.join(
                tpmdir,
                group_num,
                'lefse',
                clas
            )

            if not os.path.exists(tpm_dir):
                continue

            for specie in SPECIES:
                print('Processing %s...' % specie)
                infile = '%s/%s.res' % (tpm_dir, specie)

                if not os.path.exists(infile):
                    continue

                resdir = os.path.join(
                    res_dir,
                    group_num,
                    '6-TaxStatistical_analysis',
                    clas,
                    specie,
                    '9.Lefse'
                )

                if not os.path.exists(resdir):
                    os.makedirs(resdir)

                try:
                    res = pd.read_csv(
                        infile,
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

                    res = res.dropna(
                        subset=['Group']
                    )

                    if res.empty:
                        continue

                    res.to_csv(
                        '%s/%s_LDA.tsv' % (tpm_dir, specie),
                        sep='\t',
                        index=False,
                        encoding='utf-8-sig'
                    )

                    res.to_excel(
                        '%s/LDA.xlsx' % resdir,
                        index=False,
                        sheet_name='LDA_score'
                    )
                except Exception as e:
                    print(e)
                print('Processing %s... done' % specie)
            print('Processing %s... done' % group_num)


# ===============================
# 绘图
# ===============================
def plot_lefse(tpmdir, datadir, res_dir):

    cmd = '''
    {0} {1}/tax_LDAscore.R {2} {3} {4} > {2}/tax_LDAscore.log 2>&1
    '''.format(
        Rscript_j,
        scripts_path,
        tpmdir,
        datadir,
        res_dir
    )

    os.system(cmd)


# ===============================
# main
# ===============================
def main():

    parser = argparse.ArgumentParser()

    parser.add_argument(
        '-I',
        '--i_datadir',
        required=True
    )

    parser.add_argument(
        '--res_dir',
        default='Result'
    )

    parser.add_argument(
        '--tpmdir',
        default='tax_diff'
    )

    parser.add_argument(
        '--pre_resdir',
        default='Result'
    )

    parser.add_argument(
        '-t',
        '--threads',
        type=int,
        default=max(cpu_count()-1, 1)
    )

    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.res_dir)
    tpmdir = os.path.abspath(args.tpmdir)
    pre_resdir = os.path.abspath(args.pre_resdir)

    print('Running LEfSe with %s threads...' % args.threads)

    lefse(
        datadir,
        tpmdir,
        pre_resdir,
        args.threads
    )

    get_table(
        datadir,
        tpmdir,
        res_dir
    )

    plot_lefse(
        tpmdir,
        datadir,
        res_dir
    )


if __name__ == '__main__':
    main()