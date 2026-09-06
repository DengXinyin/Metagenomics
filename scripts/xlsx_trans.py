#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024
import os
import argparse
import openpyxl
from openpyxl.styles import Font, Border, Side, Alignment
import pandas as pd


def xlsx_trans(resdir):
    for dirpath, dirnames, filenames in os.walk(resdir):
        for file in filenames:
            if file.endswith(".xlsx"):
                file_dir = os.path.join(dirpath, file)
                try:
                    # 加载 Excel 工作簿
                    wb = openpyxl.load_workbook(file_dir)
                    # 选择工作表
                    ws = wb.active
                    # 定义字体，例如：黑色宋体
                    font = Font(color="000000", bold=False, name=u'宋体')
                    # 定义边框，例如：细黑色边框
                    thin_border = Border(left=Side(style='thin', color='000000'),
                                        right=Side(style='thin', color='000000'),
                                        top=Side(style='thin', color='000000'),
                                        bottom=Side(style='thin', color='000000'))
                    # 定义对齐方式，例如：水平和垂直都居中
                    alignment = Alignment(horizontal='center', vertical='center')
                    # 设置特定单元格的样式
                    for row in ws.iter_rows():
                        for cell in row:
                            cell.font = font
                            cell.border = thin_border
                            cell.alignment = alignment

                    # 保存工作簿
                    wb.save(file_dir)
                except KeyError as e:
                    # print("error:", e)
                    print("Failed to load the file:", file_dir)


def main():
    parser = argparse.ArgumentParser(
        description='This script will perform a difference analysis')
    parser.add_argument('--res', type=str, default='Result', help='the dir of res')
    args = parser.parse_args()

    resdir = os.path.abspath(args.res)

    xlsx_trans(resdir)


if __name__ == '__main__':
    main()
