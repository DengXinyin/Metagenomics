#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Update version of pdf2png.py

import os
import sys
import argparse
import logging
from multiprocessing import Pool, cpu_count

import fitz

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger(__name__)


def pdf2png(args):
    pic, zoom = args
    try:
        pdf_doc = fitz.open(pic)
        mat = fitz.Matrix(zoom, zoom)
        pix = pdf_doc[0].get_pixmap(matrix=mat)
        png = os.path.splitext(pic)[0] + '.png'
        pix.save(png)
        return ('ok', pic, png)
    except fitz.fitz.EmptyFileError:
        return ('empty', pic, None)
    except Exception as e:
        return ('error', pic, str(e))


def changefile(path, zoom=4, workers=None):
    if workers is None:
        workers = min(8, cpu_count())

    pdf_files = []
    for dirpath, _dirnames, filenames in os.walk(path):
        for file_name in filenames:
            if not file_name.lower().endswith('.pdf'):
                continue
            pdf_files.append((os.path.join(dirpath, file_name), zoom))

    if not pdf_files:
        log.warning('未找到 PDF 文件: %s', path)
        return

    log.info('发现 %d 个 PDF 文件，使用 %d 进程并行转换', len(pdf_files), workers)

    ok = empty = error = 0
    with Pool(processes=workers) as pool:
        for status, pic, info in pool.imap_unordered(pdf2png, pdf_files, chunksize=1):
            if status == 'ok':
                ok += 1
                log.info('转换 %s -> %s', pic, info)
            elif status == 'empty':
                empty += 1
                log.warning('无法打开空 PDF: %s', pic)
            else:
                error += 1
                log.error('转换 %s 失败: %s', pic, info)

    log.info('PDF 转换统计: 成功 %d, 空文件 %d, 失败 %d', ok, empty, error)


def main():
    parser = argparse.ArgumentParser(description='Convert PDF first page to PNG (update version)')
    parser.add_argument('-resDir', '--res-dir', type=str, required=True, help='directory to recursively convert')
    parser.add_argument('--zoom', type=int, default=4, help='render zoom factor')
    parser.add_argument('-j', '--jobs', type=int, default=None, help='number of parallel workers (default: min(8, cpu_count))')
    args = parser.parse_args()

    res_dir = os.path.abspath(args.res_dir)
    if not os.path.isdir(res_dir):
        log.error('目录不存在: %s', res_dir)
        sys.exit(1)

    try:
        changefile(res_dir, args.zoom, args.jobs)
        log.info('pdf2png 完成')
    except Exception as e:
        log.error('pdf2png 失败: %s', e)
        sys.exit(1)


if __name__ == '__main__':
    main()
