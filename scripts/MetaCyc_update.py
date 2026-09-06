#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
MetaCyc_update.py

使用 diamond 对非冗余基因进行 MetaCyc 数据库注释，并生成基因水平的 MetaCyc TPM 表。
"""

import os
import sys
import argparse
import subprocess
import logging
import pandas as pd

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger(__name__)

DIAMOND_COLS = ['qseqid', 'sseqid', 'pident', 'length', 'mismatch', 'gapopen',
                'qstart', 'qend', 'sstart', 'send', 'evalue', 'bitscore']


def run_cmd(cmd):
    log.info('执行命令: %s', cmd.strip().split('\n')[0])
    subprocess.run(cmd, shell=True, check=True)


def ensure_header(out_file):
    with open(out_file, 'r') as f:
        content = f.read()
    if not content.strip():
        with open(out_file, 'w') as f:
            f.write('\t'.join(DIAMOND_COLS) + '\n')


def metacyc_diamond(dbdir, prodigal_dir, metacyc_dir):
    out_file = os.path.join(metacyc_dir, 'MetaCyc_anno.txt')
    cmd = '''diamond blastx --threads 30 --db {0}/MetaCyc/MetaCyc -e 1e-5 \
--query {1}/unique_gene.fasta --out {2} \
--outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore
'''.format(dbdir, prodigal_dir, out_file)
    run_cmd(cmd)
    ensure_header(out_file)


def get_metacyc_table(dbdir, metacyc_dir, anno_dir, bowtie):
    metacyc_map_path = os.path.join(dbdir, 'MetaCyc', 'MetaCyc_map.txt')
    if not os.path.exists(metacyc_map_path):
        log.warning('MetaCyc 映射文件不存在: %s，使用占位映射', metacyc_map_path)
        metacyc_map = pd.DataFrame(columns=['protein_id', 'MetaCyc'])
    else:
        metacyc_map = pd.read_csv(metacyc_map_path, sep='\t')
        if 'MetaCyc' not in metacyc_map.columns:
            metacyc_map.columns = ['protein_id', 'MetaCyc'] + ['col{}'.format(i) for i in range(2, metacyc_map.shape[1])]

    gene_tax = pd.read_csv(os.path.join(anno_dir, 'gene.taxonomy.csv'), index_col=0)
    gene_tax['taxonomy'] = [';'.join(str(x) for x in row) for row in gene_tax.values]
    gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
    gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]

    metacyc = pd.read_csv(os.path.join(metacyc_dir, 'MetaCyc_anno.txt'), sep='\t',
                          header=None, names=DIAMOND_COLS, dtype={'qseqid': str, 'sseqid': str})
    if metacyc.empty:
        gene_tpm = pd.read_csv(os.path.join(bowtie, 'gene_tpm.csv'))
        out_cols = ['GeneID', 'taxonomy', 'MetaCyc'] + list(gene_tpm.columns[1:])
        pd.DataFrame(columns=out_cols).to_csv(os.path.join(metacyc_dir, 'MetaCyc.tpm.csv'), index=False, encoding='utf-8-sig')
        return

    metacyc = metacyc.loc[:, ['qseqid', 'sseqid', 'evalue']]
    metacyc = metacyc.loc[metacyc.groupby('qseqid')['evalue'].idxmin()]
    metacyc['protein_id'] = metacyc['sseqid'].str.split('|').str[1] if metacyc['sseqid'].str.contains('|').any() else metacyc['sseqid']
    metacyc_ano = pd.merge(left=metacyc, right=metacyc_map, on='protein_id', how='left')
    metacyc_ano = metacyc_ano.loc[:, ['qseqid', 'MetaCyc']].rename(columns={'qseqid': 'GeneID'})
    metacyc_ano = metacyc_ano.dropna(subset=['MetaCyc'])
    metacyc_ano = pd.merge(left=gene_tax, right=metacyc_ano, on='GeneID')

    gene_tpm = pd.read_csv(os.path.join(bowtie, 'gene_tpm.csv'))
    gene_metacyc_tpm = pd.merge(left=metacyc_ano, right=gene_tpm, on='GeneID')
    gene_metacyc_tpm.to_csv(os.path.join(metacyc_dir, 'MetaCyc.tpm.csv'), index=False, encoding='utf-8-sig')

    k = gene_metacyc_tpm.shape[1]
    if k > 3:
        metacyc_cat = gene_metacyc_tpm.iloc[:, [2] + list(range(3, k))].groupby('MetaCyc').sum()
        metacyc_cat.to_excel(os.path.join(metacyc_dir, 'MetaCyc.Category.tpm.xlsx'), index=True)


def main():
    parser = argparse.ArgumentParser(description='MetaCyc 数据库注释（diamond）')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='Annotation 结果目录')
    parser.add_argument('--MetaCycdir', type=str, default='MetaCyc', help='MetaCyc 输出目录')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='prodigal 结果目录')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='数据库目录')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='bowtie 结果目录')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    prodigal_dir = os.path.abspath(args.prodigal)
    metacyc_dir = os.path.abspath(args.MetaCycdir)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)

    os.makedirs(metacyc_dir, exist_ok=True)

    try:
        log.info('开始 MetaCyc diamond 比对')
        metacyc_diamond(dbdir, prodigal_dir, metacyc_dir)
        log.info('开始生成 MetaCyc 丰度表')
        get_metacyc_table(dbdir, metacyc_dir, anno_dir, bowtie)
        log.info('MetaCyc 注释完成，输出: %s', metacyc_dir)
    except Exception as e:
        log.error('MetaCyc 注释失败: %s', e)
        sys.exit(1)


if __name__ == '__main__':
    main()
