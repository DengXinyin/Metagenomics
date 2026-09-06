#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024
import os
import argparse


def main():
    parser = argparse.ArgumentParser(
        description='This script will generate otu_tax.xlsx')
    parser.add_argument('--res1', type=str, required=True, help='the dir of res1')
    parser.add_argument('--res2', type=str, required=True, help='the dir of res2')
    parser.add_argument('--res3', type=str, required=True, help='the dir of res3')
    parser.add_argument('--readme', type=str, required=True, help='the dir of README')
    args = parser.parse_args()

    res1 = os.path.abspath(args.res1)
    res2 = os.path.abspath(args.res2)
    res3 = os.path.abspath(args.res3)
    readme = os.path.abspath(args.readme)
    wkdir = os.getcwd()
    cmd = '''
cp -r {0} {1}
cp -r {2} {1}
cp -r {3} {1}
cp -r {4}/README_NOana.txt {1}/Result'''.format(res1, wkdir, res2, res3, readme)
    os.system(cmd)


if __name__ == '__main__':
    main()
