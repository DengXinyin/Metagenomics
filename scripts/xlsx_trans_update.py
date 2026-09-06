#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Update version of xlsx_trans.py

import os
import sys
import argparse
import logging
from multiprocessing import Pool, cpu_count

import openpyxl
from openpyxl.styles import Font, Border, Side, Alignment

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger(__name__)


def _format_xlsx(args):
    file_dir, font_name = args
    try:
        wb = openpyxl.load_workbook(file_dir)
        ws = wb.active
        font = Font(color='000000', bold=False, name=font_name)
        thin_border = Border(
            left=Side(style='thin', color='000000'),
            right=Side(style='thin', color='000000'),
            top=Side(style='thin', color='000000'),
            bottom=Side(style='thin', color='000000')
        )
        alignment = Alignment(horizontal='center', vertical='center')
        for row in ws.iter_rows():
            for cell in row:
                cell.font = font
                cell.border = thin_border
                cell.alignment = alignment
        wb.save(file_dir)
        return ('ok', file_dir, None)
    except Exception as e:
        return ('error', file_dir, str(e))


def xlsx_trans(resdir, font_name='Times New Roman', workers=None):
    if workers is None:
        workers = min(8, cpu_count())

    xlsx_files = []
    for dirpath, _dirnames, filenames in os.walk(resdir):
        for file in filenames:
            if not file.endswith('.xlsx'):
                continue
            xlsx_files.append((os.path.join(dirpath, file), font_name))

    if not xlsx_files:
        log.warning('未找到 xlsx 文件: %s', resdir)
        return

    log.info('发现 %d 个 xlsx 文件，使用 %d 进程并行格式化', len(xlsx_files), workers)

    ok = error = 0
    with Pool(processes=workers) as pool:
        for status, file_dir, err in pool.imap_unordered(_format_xlsx, xlsx_files, chunksize=1):
            if status == 'ok':
                ok += 1
                log.info('格式化: %s', file_dir)
            else:
                error += 1
                log.error('无法格式化文件 %s: %s', file_dir, err)

    log.info('xlsx 格式化统计: 成功 %d, 失败 %d', ok, error)


def main():
    parser = argparse.ArgumentParser(description='Format xlsx files (update version)')
    parser.add_argument('--res', type=str, default='Result', help='the dir of res')
    parser.add_argument('--font', type=str, default=os.environ.get('METAGE_FONT', 'Times New Roman'), help='font name')
    parser.add_argument('-j', '--jobs', type=int, default=None, help='number of parallel workers (default: min(8, cpu_count))')
    args = parser.parse_args()

    resdir = os.path.abspath(args.res)
    if not os.path.isdir(resdir):
        log.error('目录不存在: %s', resdir)
        sys.exit(1)

    try:
        xlsx_trans(resdir, args.font, args.jobs)
        log.info('xlsx_trans 完成')
    except Exception as e:
        log.error('xlsx_trans 失败: %s', e)
        sys.exit(1)


if __name__ == '__main__':
    main()
