#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""Shared four-distance beta-diversity calculation and PCoA visualization."""

import logging
import os
import re

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from Bio import Phylo

LOG = logging.getLogger(__name__)


def read_metadata(datadir):
    path = os.path.join(os.path.abspath(datadir), 'sample-metadata.tsv')
    data = pd.read_csv(path, sep='\t', skiprows=[1], dtype=str)
    if 'sample-id' not in data.columns:
        raise ValueError('sample-metadata.tsv 缺少 sample-id 列')
    return data.dropna(subset=['sample-id'])


def read_abundance(path, sample_ids, excel_sheet=None):
    if path.lower().endswith(('.xlsx', '.xls')):
        data = pd.read_excel(path, sheet_name=excel_sheet or 'relative')
    else:
        data = pd.read_csv(path, sep=None, engine='python')
    if data.empty or data.shape[1] < 3:
        raise ValueError('丰度表为空或列数不足')
    feature = data.columns[0]
    samples = [x for x in sample_ids if x in data.columns]
    if len(samples) < 3:
        raise ValueError('与 metadata 匹配的样本少于 3 个')
    values = data.set_index(feature)[samples].apply(pd.to_numeric, errors='coerce').fillna(0.0)
    values.index = values.index.map(lambda x: str(x).strip())
    values = values.groupby(level=0, sort=False).sum()
    if (values.to_numpy() < 0).any():
        raise ValueError('丰度表包含负值')
    values = values.loc[values.sum(axis=1) > 0]
    if len(values) < 2:
        raise ValueError('非零特征少于 2 个')
    return values


def read_tree(path):
    tree = Phylo.read(os.path.abspath(path), 'newick')
    tips = tree.get_terminals()
    names = [tip.name for tip in tips]
    if len(names) < 2 or any(not x for x in names) or len(names) != len(set(names)):
        raise ValueError('Newick 树叶节点不足、为空或不唯一')
    clades = [x for x in tree.find_clades(order='preorder') if x is not tree.root]
    if any(x.branch_length is None for x in clades):
        raise ValueError('Newick 树存在缺失的分支长度')
    if any(float(x.branch_length) < 0 for x in clades):
        raise ValueError('Newick 树存在负分支长度')
    return tree


def _alias(value):
    return re.sub(r'\s+', '_', str(value).strip())


def align_to_tree(abundance, tree):
    tips = [tip.name for tip in tree.get_terminals()]
    exact = set(tips)
    aliases = {}
    duplicated = set()
    for tip in tips:
        key = _alias(tip)
        if key in aliases and aliases[key] != tip:
            duplicated.add(key)
        aliases[key] = tip
    mapping = {}
    for feature in abundance.index:
        if feature in exact:
            mapping[feature] = feature
        elif _alias(feature) in aliases and _alias(feature) not in duplicated:
            mapping[feature] = aliases[_alias(feature)]
    if len(mapping) < 2:
        raise ValueError('丰度特征与树叶节点仅匹配 %d 个，至少需要 2 个' % len(mapping))
    result = abundance.loc[list(mapping)].copy()
    result.index = [mapping[x] for x in result.index]
    return result.groupby(level=0, sort=False).sum(), mapping


def _pairwise(abundance, distance):
    names = list(abundance.columns)
    matrix = np.zeros((len(names), len(names)), dtype=float)
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            matrix[i, j] = matrix[j, i] = distance(
                abundance.iloc[:, i].to_numpy(float), abundance.iloc[:, j].to_numpy(float))
    return pd.DataFrame(matrix, index=names, columns=names)


def bray_curtis(abundance):
    def distance(a, b):
        den = np.sum(a + b)
        return 0.0 if den == 0 else float(np.sum(np.abs(a - b)) / den)
    return _pairwise(abundance, distance)


def binary_jaccard(abundance):
    def distance(a, b):
        a, b = a > 0, b > 0
        union = np.logical_or(a, b).sum()
        return 0.0 if union == 0 else float(np.logical_xor(a, b).sum() / union)
    return _pairwise(abundance, distance)


def unifrac(abundance, tree, weighted):
    tips = [tip.name for tip in tree.get_terminals()]
    position = {name: i for i, name in enumerate(tips)}
    tip_values = np.zeros((len(tips), abundance.shape[1]), dtype=float)
    for name, values in abundance.iterrows():
        tip_values[position[name], :] = values.to_numpy(float)
    branch_values, lengths = [], []
    for clade in tree.find_clades(order='preorder'):
        if clade is tree.root:
            continue
        indices = [position[x.name] for x in clade.get_terminals()]
        branch_values.append(tip_values[indices, :].sum(axis=0))
        lengths.append(float(clade.branch_length))
    branch_values, lengths = np.asarray(branch_values), np.asarray(lengths)
    totals = abundance.sum(axis=0).to_numpy(float)
    names = list(abundance.columns)
    result = np.zeros((len(names), len(names)), dtype=float)
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            if weighted:
                a = branch_values[:, i] / totals[i] if totals[i] else np.zeros(len(lengths))
                b = branch_values[:, j] / totals[j] if totals[j] else np.zeros(len(lengths))
                num, den = np.sum(lengths * np.abs(a-b)), np.sum(lengths * (a+b))
            else:
                a, b = branch_values[:, i] > 0, branch_values[:, j] > 0
                num = np.sum(lengths[np.logical_xor(a, b)])
                den = np.sum(lengths[np.logical_or(a, b)])
            result[i, j] = result[j, i] = 0.0 if den == 0 else float(num / den)
    return pd.DataFrame(result, index=names, columns=names)


def pcoa(distance):
    values = distance.to_numpy(float)
    n = len(values)
    center = np.eye(n) - np.ones((n, n)) / n
    gram = -0.5 * center.dot(values ** 2).dot(center)
    eigenvalues, eigenvectors = np.linalg.eigh(gram)
    order = np.argsort(eigenvalues)[::-1]
    eigenvalues, eigenvectors = eigenvalues[order], eigenvectors[:, order]
    positive = eigenvalues > max(1e-12, eigenvalues[0] * 1e-12)
    eigenvalues, eigenvectors = eigenvalues[positive], eigenvectors[:, positive]
    if len(eigenvalues) < 2:
        raise ValueError('距离矩阵不足以生成二维 PCoA')
    coordinates = eigenvectors[:, :2] * np.sqrt(eigenvalues[:2])
    explained = eigenvalues[:2] / eigenvalues.sum() * 100
    return pd.DataFrame(coordinates, index=distance.index, columns=['PCoA1', 'PCoA2']), explained


def save_result(name, distance, outdir, metadata, title):
    os.makedirs(outdir, exist_ok=True)
    distance.to_csv(os.path.join(outdir, name + '_distance.csv'), encoding='utf-8-sig')
    coordinates, explained = pcoa(distance)
    coordinates.to_csv(os.path.join(outdir, name + '_PCoA_coordinates.csv'), encoding='utf-8-sig')
    group_columns = [x for x in metadata.columns if x != 'sample-id']
    groups = metadata.set_index('sample-id')[group_columns[0]] if group_columns else None
    labels = groups.reindex(coordinates.index).fillna('NA') if groups is not None else pd.Series('All', index=coordinates.index)
    fig, ax = plt.subplots(figsize=(7.5, 6))
    for label in labels.drop_duplicates():
        selected = labels == label
        ax.scatter(coordinates.loc[selected, 'PCoA1'], coordinates.loc[selected, 'PCoA2'], label=label, s=38)
    ax.axhline(0, color='grey', linestyle='--', linewidth=.7)
    ax.axvline(0, color='grey', linestyle='--', linewidth=.7)
    ax.set_xlabel('PCoA1 (%.2f%%)' % explained[0])
    ax.set_ylabel('PCoA2 (%.2f%%)' % explained[1])
    ax.set_title('%s - %s' % (title, name))
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(os.path.join(outdir, name + '_PCoA.png'), dpi=300)
    fig.savefig(os.path.join(outdir, name + '_PCoA.pdf'))
    plt.close(fig)


def run_four(abundance, tree, outdir, metadata, title):
    save_result('bray_curtis', bray_curtis(abundance), outdir, metadata, title)
    save_result('jaccard_binary', binary_jaccard(abundance), outdir, metadata, title)
    aligned, mapping = align_to_tree(abundance, tree)
    pd.DataFrame({'feature_id': list(mapping), 'tree_tip_id': list(mapping.values())}).to_csv(
        os.path.join(outdir, 'feature_tree_match.tsv'), sep='\t', index=False)
    save_result('weighted_unifrac', unifrac(aligned, tree, True), outdir, metadata, title)
    save_result('unweighted_unifrac', unifrac(aligned, tree, False), outdir, metadata, title)
    return len(mapping)
