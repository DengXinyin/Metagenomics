#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def func_table(bowtie, anno_dir, mapdir, dbdir, func_anno):
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie)
    ano_all = pd.read_csv('%s/func.emapper.annotations' % func_anno, sep='\t')
    ano_all = ano_all.rename(columns={'#query': 'GeneID', 'eggNOG_OGs': 'eggNOG', 'KEGG_ko': 'KO', 'GOs': 'GO'})

    tax_cla = ['eggNOG', 'KEGG', 'CAZy', 'GO']
    for cla in tax_cla:
        cla_dir = os.path.join(anno_dir, cla)
        if not os.path.exists(cla_dir):
            os.mkdir(cla_dir)

    # eggNOG
    cog = pd.read_csv('%s/eggNOG/cognames2003-2014.tab' % mapdir, sep='\t')
    cogname = pd.read_csv('%s/eggNOG/cogfun2003-2014.tab' % mapdir, sep='\t')
    kog = pd.read_excel('%s/eggNOG/kog_name.xlsx' % mapdir)

    eggNOG = ano_all.loc[:, ['GeneID', 'eggNOG']]
    eggNOG['eggNOG'] = eggNOG['eggNOG'].str.split(',').str[0]
    eggNOG['eggNOG'] = eggNOG['eggNOG'].str.split('@').str[0]

    eggNOG_COG_ano = pd.merge(left=eggNOG, right=cog, left_on='eggNOG', right_on='COG')
    eggNOG_COG_ano = pd.merge(left=eggNOG_COG_ano, right=cogname, left_on='category', right_on='category')
    eggNOG_COG_ano = eggNOG_COG_ano.loc[:, ['GeneID', 'eggNOG', 'description', 'category', 'category_description']]
    eggNOG_kOG_ano = pd.merge(left=eggNOG, right=kog, left_on='eggNOG', right_on='kog_ID')
    eggNOG_kOG_ano = eggNOG_kOG_ano.loc[:, ['GeneID', 'eggNOG', 'description', 'category', 'category_description']]

    eggNOG_ano = pd.concat([eggNOG_COG_ano, eggNOG_kOG_ano], axis=0).reset_index(drop=True)

    # 丰度表
    eggNOG_tpm = pd.merge(left=eggNOG_ano, right=gene_tpm, on='GeneID')
    eggNOG_tpm.to_csv('%s/eggNOG/eggNOG.tpm.csv' % anno_dir, index=False, encoding='utf-8-sig')

    eggNOG_category = eggNOG_tpm.drop(['GeneID', 'eggNOG', 'description'], axis=1)
    eggNOG_category['category_description'] = eggNOG_category['category'].str.cat(
        eggNOG_category['category_description'], sep=':')
    eggNOG_category['category_description'] = eggNOG_category['category_description'].str.strip()
    eggNOG_category = eggNOG_category.drop(['category'], axis=1)
    eggNOG_category = eggNOG_category.groupby('category_description').sum()
    eggNOG_category.to_excel('%s/eggNOG/eggNOG.Category.tpm.xlsx' % anno_dir, index=True)

    # KEGG
    ko_map = pd.read_excel('%s/KEGG/KO_map.xlsx' % mapdir)
    kegg_level = pd.read_csv('%s/KEGG/kegg_level.txt' % mapdir, sep='\t')

    ko = ano_all.loc[:, ['GeneID', 'KO']]
    ko = ko[ko['KO'] != '-']
    # ko['KO'] = ko['KO'].str.split(',').str[0]
    ko['KO'] = ko['KO'].str.split(',')
    ko = ko.explode('KO').drop_duplicates()
    ko['KO'] = ko['KO'].str.split('ko:').str[1]

    ko_anno = pd.merge(left=ko, right=ko_map, left_on='KO', right_on='ko_ID')
    ko_anno = pd.merge(left=ko_anno, right=kegg_level, on='level3_pathway_ID')
    ko_anno = ko_anno.drop(['ko_ID'], axis=1)

    # 丰度表
    kegg_tpm = pd.merge(left=ko_anno, right=gene_tpm, on='GeneID')
    kegg_tpm.to_csv('%s/KEGG/KEGG.tpm.csv' % anno_dir, index=False, encoding='utf-8-sig')

    kegg_l1 = pd.concat([kegg_tpm.iloc[:, 3], kegg_tpm.iloc[:, 6:]], axis=1)
    kegg_l1 = kegg_l1.groupby('level1_pathway_name').sum()
    kegg_l1.to_excel('%s/KEGG/level1.tpm.xlsx' % anno_dir, index=True)

    kegg_l2 = pd.concat([kegg_tpm.iloc[:, 4], kegg_tpm.iloc[:, 6:]], axis=1)
    kegg_l2 = kegg_l2.groupby('level2_pathway_name').sum()
    kegg_l2.to_excel('%s/KEGG/level2.tpm.xlsx' % anno_dir, index=True)

    kegg_l3 = pd.concat([kegg_tpm.iloc[:, [2, 5]], kegg_tpm.iloc[:, 6:]], axis=1)
    kegg_l3 = kegg_l3.groupby(['level3_pathway_ID', 'level3_pathway_name']).sum()
    kegg_l3.to_excel('%s/KEGG/level3.tpm.xlsx' % anno_dir, index=True)

    # CAZy
    CAZy_map = pd.read_csv('%s/CAZy/CAZy_map.tsv' % dbdir, sep='\t')
    CAZy = ano_all.loc[:, ['GeneID', 'CAZy']]
    CAZy = CAZy[CAZy['CAZy'] != '-']
    CAZy['CAZy'] = CAZy['CAZy'].str.split(',').str[0]
    CAZy_anno = pd.merge(left=CAZy, right=CAZy_map, on='CAZy')

    # 丰度表
    gene_CAZy_tpm = pd.merge(left=CAZy_anno, right=gene_tpm, on='GeneID')
    gene_CAZy_tpm.to_csv('%s/CAZy/gene.CAZy.tpm.csv' % anno_dir, index=False, encoding='utf-8-sig')

    k = gene_CAZy_tpm.shape[1]
    CAZy_tpm = gene_CAZy_tpm.iloc[:, [1] + list(range(4, k))]
    CAZy_tpm = CAZy_tpm.groupby('CAZy').sum()
    CAZy_tpm.to_excel('%s/CAZy/CAZy.tpm.xlsx' % anno_dir, index=True)

    CAZy_Category_tpm = gene_CAZy_tpm.iloc[:, 3:]
    CAZy_Category_tpm = CAZy_Category_tpm.groupby('Category').sum()
    CAZy_Category_tpm.to_excel('%s/CAZy/CAZy.Category.tpm.xlsx' % anno_dir, index=True)

    # Go
    go_map = pd.read_csv('%s/GO/GO_map.txt' % dbdir, sep='\t')
    go = ano_all.loc[:, ['GeneID', 'GO']]
    go = go[go['GO'] != '-']
    go['GO'] = go['GO'].str.split(',')
    go = go.explode('GO').drop_duplicates()
    go_anno = pd.merge(left=go, right=go_map, left_on='GO', right_on='GO_ID')
    go_anno = go_anno.drop(['GO_ID'], axis=1)

    # 丰度表
    go_tpm = pd.merge(left=go_anno, right=gene_tpm, on='GeneID')
    go_tpm.to_csv('%s/GO/GO.tpm.csv' % anno_dir, index=False, encoding='utf-8-sig')


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='the dir of database')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    parser.add_argument('--mapdir', type=str, default='/home/wangli/microbiome/microbiome', help='the dir of map')
    parser.add_argument('--fun_anno', type=str, default='Annotation', help='the dir of map')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)
    mapdir = os.path.abspath(args.mapdir)
    func_anno = os.path.abspath(args.fun_anno)
    if not os.path.exists(anno_dir):
        os.mkdir(anno_dir)

    # bowtie = r'D:\宏基因组更新\bowtie'
    # anno_dir = r'D:\宏基因组更新\Annotation'
    # mapdir = r'D:\宏基因组更新\database'
    # dbdir = r'D:\宏基因组更新\database'

    func_table(bowtie, anno_dir, mapdir, dbdir, func_anno)

if __name__ == '__main__':
    main()
