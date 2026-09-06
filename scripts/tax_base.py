#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import shutil
import argparse
import pandas as pd
from get_scriptspath import scripts_path, Rscript_j

def krona(res_dir, anno_dir, datadir):
    if not os.path.exists(os.path.join(anno_dir, 'krona')):
        os.mkdir(os.path.join(anno_dir, 'krona'))
    sepecies_ls = ['kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species']

    all_dat = pd.read_csv('%s/All/All.taxonomy.csv' % anno_dir)
    all_dat = all_dat.drop(['GeneID'], axis=1)
    all_dat = all_dat.groupby(by=sepecies_ls, as_index=False).sum()

    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
    k = sam_gros.shape[1]
    for i in range(1, k):
        sam_gro = sam_gros.iloc[:, [0] + [i]]
        sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
        samples = sam_gro['sample-id'].to_list()
        group_num = 'group' + str(i)
        res_grodir = os.path.join(res_dir, group_num, '5-TaxAnnotation', '2.Krona')
        if not os.path.exists(res_grodir):
            os.makedirs(res_grodir)

        gro_dat = all_dat.loc[:, sepecies_ls + samples]
        command_str = ''
        for i in range(7, gro_dat.shape[1]):
            sample_tax = gro_dat.iloc[:, [i] + list(range(0, 7))]
            sample_name = gro_dat.columns[i]
            sample_tax.to_csv('%s/krona/%s.txt' % (anno_dir, sample_name), sep='\t', index=False)
            command_str = command_str + '%s/krona/%s.txt ' % (anno_dir, sample_name)
        krona = 'ktImportText %s -o %s/krona.html' % (command_str, res_grodir)
        with open('krona.sh', 'w', encoding='utf-8') as f:
            f.write(krona)
        cmd = 'bash krona.sh >krona.log 2>&1'
        os.system(cmd)


def plot(datadir, res_dir, pre_resdir):
    cmd = '''
    {0} {1}/tax_bar_plot.R {2} {3} {4} > tax_bar_plot.log 2>&1
    {0} {1}/bar_tree.R {2} {3} {4} > bar_tree.log 2>&1
    {0} {1}/tax_heatmap.R {2} {3} {4} > tax_heatmap.log 2>&1
    {0} {1}/tax_PCA.R {2} {3} {4} > tax_PCA.log 2>&1
    {0} {1}/tax_PCoA.R {2} {3} {4} > tax_PCoA.log 2>&1
    {0} {1}/tax_NMDS.R {2} {3} {4} > tax_NMDS.log 2>&1
    '''.format(Rscript_j, scripts_path, pre_resdir, datadir, res_dir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--pre_resdir', type=str, default='Result', help='the resdir')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    anno_dir = os.path.abspath(args.Annotation)
    res_dir = os.path.abspath(args.resdir)
    pre_resdir = os.path.abspath(args.pre_resdir)

    krona(res_dir, anno_dir, datadir)
    plot(datadir, res_dir, pre_resdir)

if __name__ == '__main__':
    main()
