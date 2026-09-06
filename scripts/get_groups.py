#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024
import os
import argparse
import pandas as pd


def get_groups(datadir, resdir):
    sample_group = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t')
    sample_group = sample_group.drop([0], axis=0)
    sample_group.to_excel('%s/分组信息表.xlsx' % resdir, index=False)


def main():
    parser = argparse.ArgumentParser(
        description='This script will perform a difference analysis')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, help='the dir of sample-metadata.tsv')
    parser.add_argument('--res', type=str, default='Result', help='the dir of res')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    resdir = os.path.abspath(args.res)
    get_groups(datadir, resdir)


if __name__ == '__main__':
    main()
