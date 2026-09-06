#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd
from get_scriptspath import scripts_path, Rscript_j


def plot_genelen(prodigal_dir, datadir, res_dir):
    cmd = '''
{0} {1}/gene_length.R {2} {3} {4}
'''.format(Rscript_j, scripts_path, prodigal_dir, datadir, res_dir)
    os.system(cmd)


def get_stats(prodigal_dir, res_dir):
    stat_dat = pd.read_csv('%s/unique_stats.txt' % prodigal_dir, sep='\t')
    stat_dat = stat_dat.iloc[:, list(range(0, 6)) + [8]]
    stat_dat.loc[:, 'filename'] = 'unique_gene'
    stat_dat = stat_dat.rename(columns={'filename': 'ID', 'number': 'num_contigs',
                                        'total_length': 'total_length(bp)', 'shortest': 'min_length',
                                        'longest': 'max_length', 'mean_length': 'average_length', 'N50': 'N50'})
    stat_dat.to_excel('%s/unique_gene.stat.xlsx' % prodigal_dir, index=False)
    cmd = '''
    ls -d %s/*/3-GenePredict | xargs -i cp %s/unique_gene.stat.xlsx {}
    ls -d %s/*/3-GenePredict | xargs -i cp %s/unique_gene.fasta {}
    ''' % (res_dir, prodigal_dir, res_dir, prodigal_dir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will predict CDS through prodigal')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    prodigal_dir = os.path.abspath(args.prodigal)
    res_dir = os.path.abspath(args.resdir)
    if not os.path.exists(prodigal_dir):
        os.mkdir(prodigal_dir)

    plot_genelen(prodigal_dir, datadir, res_dir)
    get_stats(prodigal_dir, res_dir)


if __name__ == '__main__':
    main()
