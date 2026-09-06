#!/usr/bin/env python
# -*- coding: utf-8 -*-
import argparse
import glob
import logging
import os
import sys

from beta_four_distances import read_abundance, read_metadata, read_tree, run_four

logging.basicConfig(level=logging.INFO, format='[%(asctime)s] %(levelname)s: %(message)s')
log = logging.getLogger(__name__)


def main():
    parser = argparse.ArgumentParser(description='物种四类 Beta 距离及 PCoA')
    parser.add_argument('-I', '--i_datadir', required=True)
    parser.add_argument('--tree', required=True)
    parser.add_argument('--tax_table', default=None)
    parser.add_argument('--resdir', default='Result')
    parser.add_argument('--outdir', default='tax_unifrac')
    args = parser.parse_args()
    try:
        metadata, tree = read_metadata(args.i_datadir), read_tree(args.tree)
        if args.tax_table:
            tables = [os.path.abspath(args.tax_table)]
        else:
            tables = sorted(glob.glob(os.path.join(os.path.abspath(args.resdir), 'group*',
                '5-TaxAnnotation', '1.Tables', 'Samples', '*', 'species.xlsx')))
        if not tables:
            raise FileNotFoundError('tax_base Result 中未找到 species.xlsx')
        for table in tables:
            group, tax_class = table.split(os.sep)[-6], table.split(os.sep)[-2]
            outdir = os.path.join(os.path.abspath(args.outdir), group, tax_class, 'species')
            abundance = read_abundance(table, metadata['sample-id'].tolist(), excel_sheet='relative')
            matched = run_four(abundance, tree, outdir, metadata, '%s/%s/species' % (group, tax_class))
            log.info('%s 完成，UniFrac 匹配 %d 个树叶节点', table, matched)
    except Exception as error:
        log.error('物种四距离分析失败: %s', error)
        sys.exit(1)


if __name__ == '__main__':
    main()
