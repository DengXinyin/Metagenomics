#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
from get_scriptspath import scripts_path, Rscript_j


def plot_corV(bowtie_dir, datadir, res_dir):
    cmd = '''
{0} {1}/sample.corr_heatmap.R {2} {3} {4}
{0} {1}/venn_flower.R {2} {3} {4}
'''.format(Rscript_j, scripts_path, bowtie_dir, datadir, res_dir)
    os.system(cmd)


def res(bowtie_dir, res_dir):
    cmd = '''
    ls -d %s/*/4-GeneAbundance | xargs -i cp %s/gene_tpm.csv {}
    ls -d %s/*/4-GeneAbundance | xargs -i cp %s/gene_count.csv {}
    ''' % (res_dir, bowtie_dir, res_dir, bowtie_dir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will run bowtie and samptools')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    bowtie_dir = os.path.abspath(args.bowtie)
    res_dir = os.path.abspath(args.resdir)

    plot_corV(bowtie_dir, datadir, res_dir)
    res(bowtie_dir, res_dir)


if __name__ == '__main__':
    main()
