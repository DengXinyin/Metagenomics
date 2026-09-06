#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import shutil
import pandas as pd
import argparse
from get_scriptspath import scripts_path


def bowtie(datadir, cleandadir, host_dir, prodigal_dir, bowtie_dir, host):
    if host == 'none':
        cmd = '''
        bash {0}/bowtie.sh {1} {2} {3} {4} {5}
        '''.format(scripts_path, datadir, cleandadir, prodigal_dir, bowtie_dir, host)
    else:
        cmd = '''
        bash {0}/bowtie.sh {1} {2} {3} {4} {5}
        '''.format(scripts_path, datadir, host_dir, prodigal_dir, bowtie_dir, host)
    os.system(cmd)


def tpm(bowtie_dir):
    count_ls = list()
    tpm_ls = list()
    files = os.listdir(bowtie_dir)
    for file in files:
        if file.endswith('_mapped_cut.txt'):
            prefix = file.split('_mapped_cut.txt')[0]
            count = pd.read_csv('%s/%s' % (bowtie_dir, file), sep='\t', index_col=0)
            count = count[count.index != '*']
            # 基因长度单位为kb
            count['RPK'] = (count['mapped_read'] * 1000) / count['length']
            count['TPM'] = (count['RPK'] * 10e6) / count['RPK'].sum()
            count_data = count.loc[:, 'mapped_read']
            count_data = count_data.rename(prefix)
            count_ls.append(count_data)
            tpm_data = count.loc[:, 'TPM']
            tpm_data = tpm_data.rename(prefix)
            tpm_ls.append(tpm_data)
    count_data_a = pd.concat(count_ls, axis=1)
    tpm_data_a = pd.concat(tpm_ls, axis=1)
    count_data_a.to_csv('%s/gene_count.csv' % bowtie_dir, index=True, encoding='utf-8-sig')
    tpm_data_a.to_csv('%s/gene_tpm.csv' % bowtie_dir, index=True, encoding='utf-8-sig')


def main():
    parser = argparse.ArgumentParser(
        description='This script will run bowtie and samptools')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--host_dir', type=str, default='de_host', help='the dir of dehost_data')
    parser.add_argument('--cleandir', type=str, default='cleandata', help='the dir of clean_data')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--host', type=str, required=True, nargs='*', help='the host of metagenome')
    # parser.add_argument('--host', type=str, default='none', choices=['none', 'human', 'mouse'],
    # 					help='the host of metagenome')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    cleandadir = os.path.abspath(args.cleandir)
    host_dir = os.path.abspath(args.host_dir)
    bowtie_dir = os.path.abspath(args.bowtie)
    prodigal_dir = os.path.abspath(args.prodigal)
    host = args.host[0]
    if not os.path.exists(bowtie_dir):
        os.mkdir(bowtie_dir)
    else:
        shutil.rmtree(bowtie_dir, ignore_errors=True)
        os.mkdir(bowtie_dir)

    bowtie(datadir, cleandadir, host_dir, prodigal_dir, bowtie_dir, host)
    tpm(bowtie_dir)


if __name__ == '__main__':
    main()
