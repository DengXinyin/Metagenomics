#!/usr/bin/env python3
"""Merge parent and incremental Kraken2 sample directories."""

import argparse
import shutil
from pathlib import Path

import pandas as pd


def active_samples(datapath):
    frame = pd.read_csv(Path(datapath) / "sample.txt", sep="\t", dtype=str).fillna("")
    if frame.shape[1] < 2:
        raise ValueError("sample.txt 至少需要两列")
    samples = [str(value).strip() for value in frame.iloc[:, 1] if str(value).strip()]
    if not samples or len(samples) != len(set(samples)):
        raise ValueError("sample.txt 的有效样本为空或重复")
    return samples


def merge(old_dir, new_dir, datapath, output_dir):
    old_dir, new_dir, output_dir = map(Path, (old_dir, new_dir, output_dir))
    output_dir.mkdir(parents=True, exist_ok=True)
    for sample in active_samples(datapath):
        source = new_dir / sample if (new_dir / sample).is_dir() else old_dir / sample
        required = (source / f"{sample}.kreport2.txt", source / f"{sample}.S.bracken.txt")
        if not source.is_dir() or any(not path.is_file() for path in required):
            raise FileNotFoundError(f"Kraken2 样本结果缺失或不完整: {sample} ({source})")
        shutil.copytree(source, output_dir / sample)


def main():
    parser = argparse.ArgumentParser(description="合并历史和新增样本 Kraken2 结果")
    parser.add_argument("--old", required=True)
    parser.add_argument("--new", required=True)
    parser.add_argument("--datapath", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    merge(args.old, args.new, args.datapath, args.out)
    print(f"Kraken2 累计结果已生成: {args.out}")


if __name__ == "__main__":
    main()
