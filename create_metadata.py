#!/usr/bin/env python3
"""
生成宏基因组 WDL 测试所需的 sample metadata 文件 data.xlsx
包含两个 sheet：
  - sample: fastqfile, sample, group
  - comparison: 定义比较组（第一列为 metadata 列名，后续为分组类别）

原始 fastq 文件命名示例：RCK1_R1.fq.gz / RCK1_R2.fq.gz
这里 fastqfile 列填写去除了 _R1/_R2 后的样本基名。
"""

import pandas as pd
from pathlib import Path

outdir = Path(__file__).parent
outfile = outdir / "data.xlsx"

# 样本设计：RCK/SCK 为 CK（对照），RS/SS 为 S（处理）
samples = [
    ("RCK1", "RCK1", "CK"),
    ("RCK2", "RCK2", "CK"),
    ("RCK3", "RCK3", "CK"),
    ("RS1",  "RS1",  "S"),
    ("RS2",  "RS2",  "S"),
    ("RS3",  "RS3",  "S"),
    ("SCK1", "SCK1", "CK"),
    ("SCK2", "SCK2", "CK"),
    ("SCK3", "SCK3", "CK"),
    ("SS1",  "SS1",  "S"),
    ("SS2",  "SS2",  "S"),
    ("SS3",  "SS3",  "S"),
]

df_sample = pd.DataFrame(samples, columns=["fastqfile", "sample", "group"])

# comparison sheet：定义一个名为 "Treatment" 的分组，包含 CK 与 S 两个水平
df_comparison = pd.DataFrame({
    "group": ["Treatment"],
    "cat1":  ["CK"],
    "cat2":  ["S"]
})

with pd.ExcelWriter(outfile, engine="openpyxl") as writer:
    df_sample.to_excel(writer, sheet_name="sample", index=False)
    df_comparison.to_excel(writer, sheet_name="comparison", index=False)

print(f"✅ 已生成 metadata 文件: {outfile}")
print(f"   样本数: {len(df_sample)}")
print(df_sample.groupby("group").size())
