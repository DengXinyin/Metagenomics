#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import shutil
import argparse
import pandas as pd
from get_scriptspath import scripts_path, Rscript_j


def get_class_exp(bacteria_tpm, type, res_grodir):
    bacteria_rel = bacteria_tpm.iloc[:, 7:].div(bacteria_tpm.iloc[:, 7:].sum())
    bacteria_rel = pd.concat([bacteria_tpm.iloc[:, 0: 7], bacteria_rel], axis=1)
    bacteria_tpm.to_csv('%s/%s/%s.taxonomy.csv' % (res_grodir, type, type),  index=False, encoding='utf-8-sig')
    # with pd.ExcelWriter('%s/%s/%s.taxonomy.xlsx' % (res_grodir, type, type)) as writer:
    # 	bacteria_tpm.to_excel(writer, sheet_name='tpm', index=False)
    # 	bacteria_rel.to_excel(writer, sheet_name='relative', index=False)
    for i in range(0, 7):
        name = bacteria_tpm.columns[i]
        bacta_tax_tpm = bacteria_tpm.iloc[:, [i] + list(range(7, len(bacteria_tpm.columns)))]
        bacta_tax_tpm = bacta_tax_tpm.groupby(by=name).sum()
        bacta_tax_rela = bacteria_rel.iloc[:, [i] + list(range(7, len(bacteria_rel.columns)))]
        bacta_tax_rela = bacta_tax_rela.groupby(by=name).sum()
        with pd.ExcelWriter('%s/%s/%s.xlsx' % (res_grodir, type, name)) as writer:
            bacta_tax_tpm.to_excel(writer, sheet_name='tpm', index=True)
            bacta_tax_rela.to_excel(writer, sheet_name='relative', index=True)


def krona(res_dir, anno_dir, datadir):
    if not os.path.exists(os.path.join(anno_dir, 'krona')):
        os.mkdir(os.path.join(anno_dir, 'krona'))
    sepecies_ls = ['kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species']

    all_dat = pd.read_csv('%s/All/All.taxonomy.csv' % anno_dir)
    all_dat = all_dat.drop(['GeneID'], axis=1)
    all_dat = all_dat.groupby(by=sepecies_ls, as_index=False).sum()

    sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str, encoding='utf-8')
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


def get_table(anno_dir, datadir, res_dir):
    # 所有级别,samples
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
        sam_gro_dc = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()

        grodir = os.path.join(res_dir, group_num, '5-TaxAnnotation', '1.Tables')
        samples_dir = os.path.join(grodir, 'Samples')
        groups_dir = os.path.join(grodir, 'Groups')
        type_ls = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
        for type in type_ls:
            if not os.path.exists(os.path.join(samples_dir, type)):
                os.makedirs(os.path.join(samples_dir, type))
            if not os.path.exists(os.path.join(groups_dir, type)):
                os.makedirs(os.path.join(groups_dir, type))
        shutil.copy('%s/gene.taxonomy.csv' % anno_dir, grodir)

        all_tpm = all_dat.loc[:, sepecies_ls + samples]
        get_class_exp(all_tpm, 'All', samples_dir)
        # Bacteria
        bacteria_tpm = all_tpm[all_tpm['kingdom'] == 'k__Bacteria']
        get_class_exp(bacteria_tpm, 'bacteria', samples_dir)
        # Archaea
        Archaea_tpm = all_tpm[all_tpm['kingdom'] == 'k__Archaea']
        get_class_exp(Archaea_tpm, 'Archaea', samples_dir)
        # Eukaryota
        Fungi_tpm = all_tpm[all_tpm['kingdom'] == 'k__Eukaryota']
        get_class_exp(Fungi_tpm, 'Fungi', samples_dir)
        # Virus
        Virus_tpm = all_tpm[all_tpm['kingdom'] == 'k__Viruses']
        get_class_exp(Virus_tpm, 'Virus', samples_dir)

        # groups
        all_group = all_tpm.groupby(by=sam_gro_dc, axis=1).mean()
        all_group = pd.concat([all_tpm.iloc[:, 0: 7], all_group], axis=1)
        get_class_exp(all_group, 'All', groups_dir)
        # Bacteria
        bacteria_tpm_gro = all_group[all_group['kingdom'] == 'k__Bacteria']
        get_class_exp(bacteria_tpm_gro, 'bacteria', groups_dir)
        # Archaea
        Archaea_tpm_gro = all_group[all_group['kingdom'] == 'k__Archaea']
        get_class_exp(Archaea_tpm_gro, 'Archaea', groups_dir)
        # Eukaryota
        Fungi_tpm_gro = all_group[all_group['kingdom'] == 'k__Eukaryota']
        get_class_exp(Fungi_tpm_gro, 'Fungi', groups_dir)
        # Virus
        Virus_tpm_gro = all_group[all_group['kingdom'] == 'k__Viruses']
        get_class_exp(Virus_tpm_gro, 'Virus', groups_dir)


def plot(datadir, res_dir):
    cmd = '''
    {0} {1}/tax_bar_plot.R {2} {3} {2} > tax_bar_plot.log 2>&1
    {0} {1}/bar_tree.R {2} {3} {2} > bar_tree.log 2>&1
    {0} {1}/tax_heatmap.R {2} {3} {2} > tax_heatmap.log 2>&1
    {0} {1}/tax_PCA.R {2} {3} {2} > tax_PCA.log 2>&1
    {0} {1}/tax_PCoA.R {2} {3} {2} > tax_PCoA.log 2>&1
    {0} {1}/tax_NMDS.R {2} {3} {2} > tax_NMDS.log 2>&1
    '''.format(Rscript_j, scripts_path, res_dir, datadir)
    os.system(cmd)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    anno_dir = os.path.abspath(args.Annotation)
    res_dir = os.path.abspath(args.resdir)

    get_table(anno_dir, datadir, res_dir)

if __name__ == '__main__':
    main()
