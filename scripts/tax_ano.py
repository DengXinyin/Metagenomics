#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024

import os
import argparse
import pandas as pd


def get_class_exp(bacteria_tpm, bacteria_rel, tax_dir):
    for i in range(1, 8):
        name = bacteria_tpm.columns[i]
        bacta_tax_tpm = bacteria_tpm.iloc[:, [i] + list(range(8, len(bacteria_tpm.columns)))]
        bacta_tax_tpm = bacta_tax_tpm.groupby(by=name).sum()
        bacta_tax_rela = bacteria_rel.iloc[:, [i] + list(range(8, len(bacteria_rel.columns)))]
        bacta_tax_rela = bacta_tax_rela.groupby(by=name).sum()
        with pd.ExcelWriter('%s/%s.xlsx' % (tax_dir, name)) as writer:
            bacta_tax_tpm.to_excel(writer, sheet_name='tpm', index=True)
            bacta_tax_rela.to_excel(writer, sheet_name='relative', index=True)


def diamond(dbdir, prodigal_dir, megan_dir, anno_dir):
    cmd = '''
diamond blastx --threads 60 --db {0}/metage -q {1}/unique_gene.fasta \
--evalue 1e-5 -o {1}/unique.daa --outfmt 100

{2}/tools/daa2rma -i {1}/unique.daa  \
-ms 50 -me 0.01 -top 50  \
-mdb {0}/megan-map-Feb2022.db  -o {1}/unique.rma

{2}/tools/rma2info -i {1}/unique.rma \
-r2c Taxonomy -v >  {3}/Tax_id.tmp.txt
sed -i '1i\GeneID\ttaxid' {3}/Tax_id.tmp.txt
'''.format(dbdir, prodigal_dir, megan_dir, anno_dir)
    os.system(cmd)


def tax_table(anno_dir, dbdir, bowtie):
    taxid = pd.read_csv('%s/Tax_id.tmp.txt' % anno_dir, sep='\t')
    tax_ano = pd.read_csv('%s/metage.taxonomy.txt' % dbdir, sep='\t')
    gene2tax = pd.merge(left=taxid, right=tax_ano, on='taxid')
    gene2tax = gene2tax.drop(['taxid'], axis=1)
    gene2tax.to_csv('%s/gene.taxonomy.csv' % anno_dir, index=False, encoding='utf-8-sig')

    tax_cla = ['All', 'bacteria', 'Archaea', 'Fungi', 'Virus']
    for cla in tax_cla:
        tax_dir = os.path.join(anno_dir, cla)
        if not os.path.exists(tax_dir):
            os.mkdir(tax_dir)

    # 所有级别
    gene_tpm = pd.read_csv('%s/gene_tpm.csv' % bowtie, index_col=0)
    all_tpm = pd.merge(left=gene2tax, right=gene_tpm, on='GeneID')
    all_rel = all_tpm.iloc[:, 8:].div(all_tpm.iloc[:, 8:].sum())
    all_rel = pd.concat([all_tpm.iloc[:, 0: 8], all_rel], axis=1)
    all_tpm.to_csv('%s/All/All.taxonomy.csv' % anno_dir, index=False, encoding='utf-8-sig')
    all_rel.to_csv('%s/All/All.taxonomy.rel.csv' % anno_dir, index=False, encoding='utf-8-sig')
    # with pd.ExcelWriter('%s/All/All.taxonomy.xlsx' % anno_dir) as writer:
    # 	all_tpm.to_excel(writer, sheet_name='tpm', index=False)
    # 	all_rel.to_excel(writer, sheet_name='relative', index=False)
    # get_class_exp(all_tpm, all_rel, '%s/All' % anno_dir)

    # # Bacteria
    # bacteria_tpm = all_tpm[all_tpm['kingdom'] == 'k__Bacteria']
    # bacteria_rel = bacteria_tpm.iloc[:, 8:].div(bacteria_tpm.iloc[:, 8:].sum())
    # bacteria_rel = pd.concat([bacteria_tpm.iloc[:, 0: 8], bacteria_rel], axis=1)
    # with pd.ExcelWriter('%s/bacteria/bacteria.taxonomy.xlsx' % anno_dir) as writer:
    # 	bacteria_tpm.to_excel(writer, sheet_name='tpm', index=False)
    # 	bacteria_rel.to_excel(writer, sheet_name='relative', index=False)
    # get_class_exp(bacteria_tpm, bacteria_rel, '%s/bacteria' % anno_dir)
    #
    # # Archaea
    # Archaea_tpm = all_tpm[all_tpm['kingdom'] == 'k__Archaea']
    # Archaea_rel = Archaea_tpm.iloc[:, 8:].div(Archaea_tpm.iloc[:, 8:].sum())
    # Archaea_rel = pd.concat([Archaea_tpm.iloc[:, 0: 8], Archaea_rel], axis=1)
    # with pd.ExcelWriter('%s/Archaea/Archaea.taxonomy.xlsx' % anno_dir) as writer:
    # 	Archaea_tpm.to_excel(writer, sheet_name='tpm', index=False)
    # 	Archaea_rel.to_excel(writer, sheet_name='relative', index=False)
    # get_class_exp(Archaea_tpm, Archaea_rel, '%s/Archaea' % anno_dir)
    #
    # # Eukaryota
    # Fungi_tpm = all_tpm[all_tpm['kingdom'] == 'k__Eukaryota']
    # Fungi_rel = Fungi_tpm.iloc[:, 8:].div(Fungi_tpm.iloc[:, 8:].sum())
    # Fungi_rel = pd.concat([Fungi_tpm.iloc[:, 0: 8], Fungi_rel], axis=1)
    # with pd.ExcelWriter('%s/Fungi/Fungi.taxonomy.xlsx' % anno_dir) as writer:
    # 	Fungi_tpm.to_excel(writer, sheet_name='tpm', index=False)
    # 	Fungi_rel.to_excel(writer, sheet_name='relative', index=False)
    # get_class_exp(Fungi_tpm, Fungi_rel, '%s/Fungi' % anno_dir)
    #
    # # Virus
    # Virus_tpm = all_tpm[all_tpm['kingdom'] == 'k__Viruses']
    # Virus_rel = Virus_tpm.iloc[:, 8:].div(Virus_tpm.iloc[:, 8:].sum())
    # Virus_rel = pd.concat([Virus_tpm.iloc[:, 0: 8], Virus_rel], axis=1)
    # with pd.ExcelWriter('%s/Virus/Virus.taxonomy.xlsx' % anno_dir) as writer:
    # 	Virus_tpm.to_excel(writer, sheet_name='tpm', index=False)
    # 	Virus_rel.to_excel(writer, sheet_name='relative', index=False)
    # get_class_exp(Virus_tpm, Virus_rel, '%s/Virus' % anno_dir)


def main():
    parser = argparse.ArgumentParser(
        description='This script will blast unique_gene.fasta and annotate it')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='the res of Annotation')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='the res of prodigal')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database/NR', help='the dir of database')
    parser.add_argument('--megandir', type=str, default='/data/data1/wangli/soft/megan', help='the dir of megan')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='the res of bowtie')
    args = parser.parse_args()

    prodigal_dir = os.path.abspath(args.prodigal)
    anno_dir = os.path.abspath(args.Annotation)
    dbdir = os.path.abspath(args.dbdir)
    megandir = os.path.abspath(args.megandir)
    bowtie = os.path.abspath(args.bowtie)
    if not os.path.exists(anno_dir):
        os.mkdir(anno_dir)

    diamond(dbdir, prodigal_dir, megandir, anno_dir)
    tax_table(anno_dir, dbdir, bowtie)


if __name__ == '__main__':
    main()
