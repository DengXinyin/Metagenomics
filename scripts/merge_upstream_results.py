#!/usr/bin/env python3
"""Overlay incremental upstream outputs on a completed parent workflow."""

import argparse
import os
import shutil
from pathlib import Path

import pandas as pd


def link_or_copy(source, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() or target.is_symlink():
        target.unlink()
    try:
        os.link(source, target)
    except OSError:
        shutil.copy2(source, target)


def overlay_tree(source, target):
    for path in Path(source).rglob("*"):
        relative = path.relative_to(source)
        destination = target / relative
        if path.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
        elif path.is_file():
            link_or_copy(path, destination)


def merge_matrix(old_path, new_path, output_path):
    """Outer-join a GeneID matrix; new sample columns replace old columns."""
    old = pd.read_csv(old_path, encoding="utf-8-sig")
    new = pd.read_csv(new_path, encoding="utf-8-sig")
    key = old.columns[0]
    if new.columns[0] != key:
        raise ValueError(f"矩阵首列不一致: {old_path} / {new_path}")
    replacement_columns = [column for column in new.columns[1:] if column in old.columns]
    old = old.drop(columns=replacement_columns)
    merged = old.merge(new, how="outer", on=key).fillna(0)
    merged.to_csv(output_path, index=False, encoding="utf-8-sig")


def merge_sample_summary(old_path, new_path, output_path):
    """Merge kneaddata summaries; rows from the new run replace matching samples."""
    old = pd.read_csv(old_path, sep="\t", encoding="utf-8-sig", dtype={"Sample_name": str})
    new = pd.read_csv(new_path, sep="\t", encoding="utf-8-sig", dtype={"Sample_name": str})
    key = "Sample_name"
    if key not in old.columns or key not in new.columns:
        raise ValueError(f"质控汇总表缺少 {key} 列: {old_path} / {new_path}")
    if list(old.columns) != list(new.columns):
        raise ValueError(f"质控汇总表列不一致: {old_path} / {new_path}")

    # Keep one row per sample.  A newly generated row is authoritative when a
    # sample is rerun, while rows for untouched historical samples are retained.
    old = old.drop_duplicates(subset=key, keep="last")
    new = new.drop_duplicates(subset=key, keep="last")
    old = old.loc[~old[key].isin(new[key])]
    merged = pd.concat([old, new], ignore_index=True)
    merged.to_csv(output_path, sep="\t", index=False, encoding="utf-8")


def read_fasta(path):
    records = {}
    current = None
    chunks = []
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if line.startswith(">"):
                if current is not None:
                    records[current] = chunks
                current = line[1:].split()[0]
                chunks = [line]
            elif current is not None:
                chunks.append(line)
    if current is not None:
        records[current] = chunks
    return records


def merge_fasta(old_path, new_path, output_path):
    records = read_fasta(old_path)
    records.update(read_fasta(new_path))
    with open(output_path, "w", encoding="utf-8") as handle:
        for chunks in records.values():
            handle.writelines(chunks)


def tabular_key(line):
    return line.split("\t", 1)[0]


def merge_tabular_records(old_path, new_path, output_path):
    comments = []
    records = {}
    for path in (old_path, new_path):
        with open(path, encoding="utf-8", errors="replace") as handle:
            for line in handle:
                if not line.strip():
                    continue
                if line.startswith("#"):
                    if line not in comments:
                        comments.append(line)
                else:
                    records[tabular_key(line)] = line
    with open(output_path, "w", encoding="utf-8") as handle:
        handle.writelines(comments)
        handle.writelines(records.values())


def merge_pair(label, old_dir, new_dir, output_root):
    old_dir = Path(old_dir)
    new_dir = Path(new_dir)
    output_dir = output_root / label
    output_dir.mkdir(parents=True, exist_ok=True)
    overlay_tree(old_dir, output_dir)
    overlay_tree(new_dir, output_dir)

    if label == "clean":
        relative = Path("table") / "sumary.txt"
        if (old_dir / relative).exists() and (new_dir / relative).exists():
            merge_sample_summary(old_dir / relative, new_dir / relative, output_dir / relative)
    elif label == "bowtie":
        for filename in ("gene_count.csv", "gene_tpm.csv"):
            if (old_dir / filename).exists() and (new_dir / filename).exists():
                merge_matrix(old_dir / filename, new_dir / filename, output_dir / filename)
    elif label == "prodigal":
        for filename in ("unique_gene.fasta", "clusterRes_rep_seq.fasta", "clusterRes_all_seqs.fasta"):
            if (old_dir / filename).exists() and (new_dir / filename).exists():
                merge_fasta(old_dir / filename, new_dir / filename, output_dir / filename)
    elif label == "tax_annotation":
        filename = "Tax_id.tmp.txt"
        if (old_dir / filename).exists() and (new_dir / filename).exists():
            merge_tabular_records(old_dir / filename, new_dir / filename, output_dir / filename)
    elif label == "func_annotation":
        for filename in ("func.emapper.annotations", "func.emapper.hits", "func.emapper.seed_orthologs"):
            if (old_dir / filename).exists() and (new_dir / filename).exists():
                merge_tabular_records(old_dir / filename, new_dir / filename, output_dir / filename)


def main():
    parser = argparse.ArgumentParser(description="合并历史上游结果和本次增量样本结果")
    parser.add_argument("--pair", nargs=3, action="append", metavar=("LABEL", "OLD_DIR", "NEW_DIR"), required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()
    output_root = Path(args.out)
    output_root.mkdir(parents=True, exist_ok=True)
    for label, old_dir, new_dir in args.pair:
        print(f"合并 {label}: {old_dir} + {new_dir}")
        merge_pair(label, old_dir, new_dir, output_root)


if __name__ == "__main__":
    main()
