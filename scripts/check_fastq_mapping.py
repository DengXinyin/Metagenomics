#!/usr/bin/env python3
import os
import re
import sys
import pandas as pd

if len(sys.argv) != 4:
    print("Usage: python check_fastq_mapping.py <fastq_dir> <mapping_file> <metadata_file>")
    sys.exit(1)

fastq_dir = sys.argv[1]
mapping_file = sys.argv[2]
metadata_file = sys.argv[3]

def extract_sample_name(filename: str) -> str:
    """
    从 fastq 文件名中提取样本基名，去掉尾部的配对标记。
    例如：
        YW91_1_1.fq.gz  -> YW91_1
        CK_1_1.fq.gz    -> CK_1
        sample-R1.fastq -> sample
        sample_R2.fq    -> sample
    """
    name = filename
    # 1) 去掉 .gz
    if name.endswith('.gz'):
        name = name[:-3]
    # 2) 去掉 .fastq 或 .fq
    for ext in ('.fastq', '.fq'):
        if name.endswith(ext):
            name = name[:-len(ext)]
            break

    # 3) 去掉末尾的配对标记
    #   支持以下情况：
    #   _R1 / _R2 / -R1 / -R2
    #   _1 / _2 / -1 / -2 （但前面不能再有 R）
    #   例如：
    #       CK_1_1 -> CK_1
    #       CK_1_R1 -> CK_1
    #       CK_1-2 -> CK_1
    base = re.sub(r'([_\-\.](?:R?[12]))$', '', name)
    return base


# 1. 获取 fastq 文件名（支持 .fq .fastq 以及 .gz 压缩）
fastq_files = [f for f in os.listdir(fastq_dir) if f.lower().endswith((".fq", ".fq.gz", ".fastq", ".fastq.gz"))]
fastq_sample_names = set()
for f in fastq_files:
    s = extract_sample_name(f)
    if s:
        fastq_sample_names.add(s)

# 2. 读取 mapping 和 metadata 文件（自动兼容带注释行的 metadata）
#    假设 mapping 文件有列名 fastqfile 和 samples，metadata 有列名 sample-id
map_df = pd.read_csv(mapping_file, sep="\t", engine='python')  # 让 pandas 自动检测分隔符（csv 或 tsv）
meta_df = pd.read_csv(metadata_file, sep="\t", comment='#', engine='python')

# 尝试容错：标准列名可能是不同大小写/带空格，做一下容错查找
def find_col(df, candidates):
    for c in candidates:
        if c in df.columns:
            return c
    # 忽略大小写匹配
    lower_map = {col.lower(): col for col in df.columns}
    for c in candidates:
        if c.lower() in lower_map:
            return lower_map[c.lower()]
    return None

fastq_col = find_col(map_df, ['fastqfile', 'fastq_file', 'fastq', 'fastq_file_name'])
sample_col = find_col(map_df, ['samples', 'sample', 'sample-id', 'sample_id'])
meta_sample_col = find_col(meta_df, ['sample-id', 'sample_id', 'sample', 'sampleid'])

if fastq_col is None or sample_col is None:
    print("❌ Mapping file 列名不包含预期列（fastqfile/samples）。请确认 mapping 文件有列名 fastqfile 和 samples。")
    sys.exit(1)
if meta_sample_col is None:
    print("❌ Metadata 文件中找不到 sample-id 列。请确认 metadata 文件包含 sample-id 列名。")
    sys.exit(1)

# 3. 检查 fastqfile 列是否都在目录中存在（匹配去掉 R1/R2 后的 base name）
map_fastq_bases = list(map_df[fastq_col].astype(str).tolist())
# 需要将 mapping 表里的 fastqfile 字段也规整为 base（如果 mapping 里已经是 base 名则保持一致）
# 先将 mapping 列中可能包含扩展名/尾部标记也做同样处理，确保比较一致
# map_fastq_processed = [extract_sample_name(os.path.basename(x)) for x in map_fastq_bases]


# missing_fastqs = [orig for orig, proc in zip(map_fastq_bases, map_fastq_bases) if proc not in fastq_sample_names]
missing_fastqs = [orig for orig in map_fastq_bases if orig not in fastq_sample_names]
extra_fastqs = [f for f in fastq_sample_names if f not in map_fastq_bases]

# 4. 检查 sample 列与 metadata 中的 sample-id 是否匹配
map_samples = list(map_df[sample_col].astype(str).tolist())
meta_samples = set(meta_df[meta_sample_col].astype(str).tolist())

missing_samples = [s for s in map_samples if s not in meta_samples]
extra_samples = [s for s in meta_samples if s not in map_samples]

# 5. 输出结果或报错退出（直接打印到 stdout/stderr）
if not missing_fastqs and not extra_fastqs and not missing_samples and not extra_samples:
    print("✅ All checks passed!")
    sys.exit(0)
else:
    print("❌ Validation failed:")
    if missing_fastqs:
        print(f"  - Mapping 中这些 fastqfile 在目录中找不到匹配的 fastq（去除 _1/_2/_R1/_R2 后的 base 未匹配）: {missing_fastqs}")
    if extra_fastqs:
        print(f"  - 目录中存在未在 mapping 表中定义的样本 base 名: {sorted(extra_fastqs)}")
    if missing_samples:
        print(f"  - Mapping 中的 sample 未在 metadata 中找到: {missing_samples}")
    if extra_samples:
        print(f"  - Metadata 中存在但不在 mapping 中的 sample: {sorted(extra_samples)}")
    sys.exit(1)
