#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

# QS群体感应数据库
import os
import pandas as pd
import re


def extract_protein_family(row):
    try:
        return re.search('SIMILARITY: Belongs to the (.*?family).', row['Sequence similarities']).group(1)
    except:
        return '-'
    

os.chdir(r'D:\download\参考基因组及注释文件\QS')
qs_dat = pd.read_excel('uniprotkb_keyword_KW_0673_2024_08_12.xlsx')
type_dict ={'AHL':
                 ['AHL','acylated homoserine lactone', 'Acyl-homoserine lactone', 'acyl homoserine lactone'],
            'DKPs':['DKP','diketopiperazines'],
            'AHQs':['AHQ', '2-Alkyl-4-quinolones', 'PQS', '2-heptyl-3-hydroxy-4-quinolone', 'HHQ', '2-heptyl-4-quinolone'],
            'DSFs':['DSF','diffusible signal factors'],
            'AI-2':['AI-2','autoinducer-2'],
            'AI-3':['AI-3','autoinducer-3'],
            'AIP': ['AIP','autoinducing peptide']
            }
# typeList = ['AHL', 'AI-2', 'AI-3', 'DSF', 'AHK', 'PQS ', 'AIP']
qs_dat = qs_dat.fillna('-')
qs_dat['Protein family'] = qs_dat.apply(extract_protein_family, axis=1)
# qs_dat['type'] = qs_dat['Function [CC]'].apply(lambda x: 
#         ', '.join([k for k, v in type_dict.items() if any(y in x for y in v)]) or 'unclear')
qs_dat.to_excel('uniprotkb_keyword_2024_08_12.xlsx', index=False)
print(qs_dat.groupby('Protein family').count())
