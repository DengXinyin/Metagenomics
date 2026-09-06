#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
COG_update.py

使用 diamond 对非冗余基因进行 COG 数据库注释，并生成基因水平的 COG TPM 表。
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
    """如果 diamond 输出为空，写入表头占位，避免 pandas 解析失败。"""
    with open(out_file, 'r') as f:
        content = f.read()
    if not content.strip():
        with open(out_file, 'w') as f:
            f.write('\t'.join(DIAMOND_COLS) + '\n')


def cog_diamond(dbdir, prodigal_dir, cog_dir):
    """diamond blastx 比对 COG 数据库。"""
    out_file = os.path.join(cog_dir, 'COG_anno.txt')
    cmd = '''diamond blastx --threads 30 --db {0}/COG/COG -e 1e-5 \
--query {1}/unique_gene.fasta --out {2} \
--outfmt 6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore
'''.format(dbdir, prodigal_dir, out_file)
    run_cmd(cmd)
    ensure_header(out_file)


def get_cog_table(dbdir, cog_dir, anno_dir, bowtie):
    """根据 diamond 结果生成 COG.tpm.csv。"""
    cog_map_path = os.path.join(dbdir, 'COG', 'cog2003-2014.csv')
    if not os.path.exists(cog_map_path):
        log.warning('COG 映射文件不存在: %s，使用占位映射', cog_map_path)
        cog_map = pd.DataFrame(columns=['protein_id', 'COG'])
    else:
        cog_map = pd.read_csv(cog_map_path, header=None, dtype=str)
        cog_map.columns = ['protein_id', 'COG'] + ['col{}'.format(i) for i in range(2, cog_map.shape[1])]

    gene_tax = pd.read_csv(os.path.join(anno_dir, 'gene.taxonomy.csv'), index_col=0)
    gene_tax['taxonomy'] = [';'.join(str(x) for x in row) for row in gene_tax.values]
    gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
    gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]

    cog = pd.read_csv(os.path.join(cog_dir, 'COG_anno.txt'), sep='\t',
                      header=None, names=DIAMOND_COLS, dtype={'qseqid': str, 'sseqid': str})
    if cog.empty:
        gene_tpm = pd.read_csv(os.path.join(bowtie, 'gene_tpm.csv'))
        out_cols = ['GeneID', 'taxonomy', 'COG'] + list(gene_tpm.columns[1:])
        pd.DataFrame(columns=out_cols).to_csv(os.path.join(cog_dir, 'COG.tpm.csv'), index=False, encoding='utf-8-sig')
        return

    cog = cog.loc[:, ['qseqid', 'sseqid', 'evalue']]
    cog = cog.loc[cog.groupby('qseqid')['evalue'].idxmin()]
    # 提取蛋白ID：处理 piped (UniRef|protID) 和 plain (WP_xxx) 两种格式
    mask = cog['sseqid'].str.contains('|', regex=False)
    cog['protein_id'] = cog['sseqid'].where(~mask, cog['sseqid'].str.split('|').str[1])
    cog['protein_id'] = cog['protein_id'].astype(str)
    cog_map['protein_id'] = cog_map['protein_id'].astype(str)
    cog_ano = pd.merge(left=cog, right=cog_map, on='protein_id', how='left')
    cog_ano = cog_ano.loc[:, ['qseqid', 'COG']].rename(columns={'qseqid': 'GeneID'})
    cog_ano = cog_ano.dropna(subset=['COG'])
    cog_ano = pd.merge(left=gene_tax, right=cog_ano, on='GeneID')

    gene_tpm = pd.read_csv(os.path.join(bowtie, 'gene_tpm.csv'))
    gene_cog_tpm = pd.merge(left=cog_ano, right=gene_tpm, on='GeneID')
    gene_cog_tpm.to_csv(os.path.join(cog_dir, 'COG.tpm.csv'), index=False, encoding='utf-8-sig')

    # 生成 COG 分类汇总表
    k = gene_cog_tpm.shape[1]
    if k > 3:
        cog_cat = gene_cog_tpm.iloc[:, [2] + list(range(3, k))].groupby('COG').sum()
        cog_cat.to_excel(os.path.join(cog_dir, 'COG.Category.tpm.xlsx'), index=True)


def main():
    parser = argparse.ArgumentParser(description='COG 数据库注释（diamond）')
    parser.add_argument('--Annotation', type=str, default='Annotation', help='Annotation 结果目录')
    parser.add_argument('--COGdir', type=str, default='COG', help='COG 输出目录')
    parser.add_argument('--prodigal', type=str, default='prodigal', help='prodigal 结果目录')
    parser.add_argument('--dbdir', type=str, default='/data/data1/wangli/database', help='数据库目录')
    parser.add_argument('--bowtie', type=str, default='bowtie', help='bowtie 结果目录（含 gene_tpm.csv）')
    args = parser.parse_args()

    anno_dir = os.path.abspath(args.Annotation)
    prodigal_dir = os.path.abspath(args.prodigal)
    cog_dir = os.path.abspath(args.COGdir)
    dbdir = os.path.abspath(args.dbdir)
    bowtie = os.path.abspath(args.bowtie)

    os.makedirs(cog_dir, exist_ok=True)

    try:
        log.info('开始 COG diamond 比对')
        cog_diamond(dbdir, prodigal_dir, cog_dir)
        log.info('开始生成 COG 丰度表')
        get_cog_table(dbdir, cog_dir, anno_dir, bowtie)
        log.info('COG 注释完成，输出: %s', cog_dir)
    except Exception as e:
        log.error('COG 注释失败: %s', e)
        sys.exit(1)


if __name__ == '__main__':
    main()
