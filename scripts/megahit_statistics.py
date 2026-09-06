#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd
from get_scriptspath import scripts_path, Rscript_j


def length_table(megahit_dir, datadir, res_dir):
    len_dir = os.path.join(megahit_dir, 'length')
    cmd = '''
{0} {1}/length_count.R {2} {3} {4}
'''.format(Rscript_j, scripts_path, len_dir, datadir, res_dir)
    os.system(cmd)


def get_contigs(megahit_dir, res_dir, datadir):
    cmd = '''
awk 'NR!=1 {print}' %s/sample.txt|while read id;do
    sample=`echo ${id}|cut -d " " -f 2|tr -d '\n\r'`
    echo ${sample}
    ls -d %s/*/2-Assembly/${sample} | xargs -i cp %s/${sample}/final.contigs.fa {}
done
''' % (datadir, res_dir, megahit_dir)
    os.system(cmd)


def stats_table(megahit_dir, datadir, res_dir):
    stat_dir = os.path.join(megahit_dir, 'length')
    stat_ls = list()
    files = os.listdir(stat_dir)
    for file in files:
        if file.endswith('_stats.txt'):
            prefix = file.split('_stats.txt')[0]
            stat_dat = pd.read_csv('%s/%s' % (stat_dir, file), sep='\t')
            stat_dat = stat_dat.iloc[:, list(range(0, 6)) + [8]]
            stat_dat.loc[:, 'filename'] = prefix
            stat_dat = stat_dat.rename(columns={'filename': 'sample', 'number': 'num_contigs',
                                                'total_length': 'total_length(bp)', 'shortest': 'min_length',
                                                'longest': 'max_length', 'mean_length': 'average_length', 'N50': 'N50'})
            stat_ls.append(stat_dat)
    statat = pd.concat(stat_ls, axis=0)
    statat.to_excel('%s/assembly_stat.xlsx' % megahit_dir, index=False)

    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        group_num = 'group' + str(i)

        sam_df = pd.merge(left=sam_gro, right=statat, left_on='sample-id', right_on='sample', how='inner')
        sam_df = sam_df.drop(['sample-id', group_num], axis=1)
        grodir = os.path.join(res_dir, group_num)
        sam_df.to_excel('%s/2-Assembly/assembly_stat.xlsx' % grodir, index=False)


def main():
    parser = argparse.ArgumentParser(
        description='This script will assemble sequence through megahit')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--megahit', type=str, default='megahit', help='the res of megahit')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    megahit_dir = os.path.abspath(args.megahit)
    res_dir = os.path.abspath(args.resdir)

    length_table(megahit_dir, datadir, res_dir)
    stats_table(megahit_dir, datadir, res_dir)


if __name__ == '__main__':
    main()
