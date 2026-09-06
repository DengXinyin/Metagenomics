#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import scipy.stats as stats
import pandas as pd
from statsmodels.stats import multitest
import os
import glob

def kw_wilcoxon(tax_dat, sam_gro, group_num):
    tax_dat = tax_dat.dropna(axis=1)
    tax_dat = tax_dat[tax_dat.apply(lambda row: len(set(row)) != 2, axis=1)].reset_index(drop=True)
    k = len(sam_gro.iloc[:, 1].unique())  # 组数
    n = sam_gro.iloc[:, 1].value_counts()  # 样本数
    n = min(n.to_numpy())
    if not tax_dat.empty and k == 2 and n > 1:
        group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
        groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
        statistic, pVal = stats.ranksums(*groups_array, axis=1)
        padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
        statistic = pd.Series(statistic).rename('statistic')
        pVal = pd.Series(pVal).rename('p_value')
        padj = pd.Series(padj).rename('padj')
        tax_dat_p = pd.concat([tax_dat, statistic, pVal, padj], axis=1)
        tax_dat_sign = tax_dat_p[tax_dat_p['p_value'] < 0.05]
        return tax_dat_p, tax_dat_sign
    elif not tax_dat.empty and k > 2 and n > 1:
        group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
        groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
        H_statistic, pVal = stats.kruskal(*groups_array, axis=1)
        padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
        H_statistic = pd.Series(H_statistic).rename('statistic')
        pVal = pd.Series(pVal).rename('p_value')
        padj = pd.Series(padj).rename('padj')
        tax_dat_p = pd.concat([tax_dat, H_statistic, pVal, padj], axis=1)
        tax_dat_sign = tax_dat_p[tax_dat_p['p_value'] < 0.05]
        return tax_dat_p, tax_dat_sign


os.chdir(r'D:\售后')
samples = pd.read_csv('data/samples.txt', sep='\t')
print(samples)
files = glob.glob(r'metage/*.metage.count.csv')
for file in files:
    prefix = file.strsplit('.metage.count.csv')[0]
    print(prefix)
    data = pd.read_csv(file)
    print(data)