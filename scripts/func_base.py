#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd
from get_scriptspath import scripts_path, Rscript_j


def plot_func(func_tmpdir, datadir, res_dir):
    cmd = '''
    {0} {1}/func_barplot.R {2} {3} {4} > {2}/func_barplot.log
    {0} {1}/func_heatmap.R {2} {3} {4} > {2}/func_heatmap.log
    {0} {1}/func_PCA.R {2} {3} {4} > {2}/func_PCA.log
    {0} {1}/func_PCOA.R {2} {3} {4} > {2}/func_PCOA.log
    {0} {1}/func_NMDS.R {2} {3} {4} > {2}/func_NMDS.log
    '''.format(Rscript_j, scripts_path, func_tmpdir, datadir, res_dir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--func_tmp', type=str, default='func_base', help='the func_base')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    res_dir = os.path.abspath(args.resdir)
    func_tmpdir = os.path.abspath(args.func_tmp)
    plot_func(func_tmpdir, datadir, res_dir)


if __name__ == '__main__':
    main()
