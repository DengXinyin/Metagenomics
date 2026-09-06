import pandas as pd
import argparse
import os
import time
from pathlib import Path

start_time = time.time()

parser = argparse.ArgumentParser(description="deal data to metadata")
parser.add_argument("-indir", required=True, type=str, help="dataDir path")
parser.add_argument("-outdir", required=True, type=str, help="output path")
parser.add_argument(
    "--allow-empty-comparison",
    action="store_true",
    help=(
        "仅供 incremental 新增样本上游使用：comparison 为空时，"
        "按 sample.group 生成一个临时 group1。完整项目元数据仍必须提供 comparison。"
    ),
)
args = parser.parse_args()

Path(args.outdir).mkdir(parents=True, exist_ok=True)

# 读取数据：按列指定 dtype，避免类型推断
excel_file = os.path.join(args.indir, "data.xlsx")
df_sample = pd.read_excel(
    excel_file,
    sheet_name="sample",
    dtype={"fastqfile": str, "sample": str, "group": str},
    engine="openpyxl",
)
df_comp = pd.read_excel(
    excel_file,
    sheet_name="comparison",
    header=0,
    dtype=str,
    engine="openpyxl",
)

required_sample_columns = {"fastqfile", "sample", "group"}
missing_sample_columns = required_sample_columns - set(df_sample.columns)
if missing_sample_columns:
    raise ValueError(
        "sample sheet 缺少必要列: " + ", ".join(sorted(missing_sample_columns))
    )

for column in ["fastqfile", "sample", "group"]:
    df_sample[column] = df_sample[column].fillna("").astype(str).str.strip()
    empty_rows = df_sample.index[df_sample[column] == ""].tolist()
    if empty_rows:
        excel_rows = ", ".join(str(i + 2) for i in empty_rows)
        raise ValueError(f"sample sheet 的 {column} 列存在空值，Excel 行: {excel_rows}")

for column in ["fastqfile", "sample"]:
    duplicate_values = sorted(
        df_sample.loc[df_sample[column].duplicated(keep=False), column].unique()
    )
    if duplicate_values:
        raise ValueError(
            f"sample sheet 的 {column} 必须唯一，重复值: {', '.join(duplicate_values)}"
        )

if df_comp.empty and not args.allow_empty_comparison:
    raise ValueError(
        "comparison sheet 仅含表头、没有比较定义。"
        "请至少填写一行比较：第一列为比较名称，后续列填写 sample sheet 的 group 列中的分组值。"
    )

# 生成 sample.txt
sample_path = os.path.join(args.outdir, "sample.txt")
df_sample[["fastqfile", "sample"]].to_csv(sample_path, sep="\t", index=False)

# 构建 group_map：每一行 comparison 定义一个用于下游比较的分组集合。
# 表头不是比较定义，不能在空表时当作成员使用。
sample_groups = {
    str(value).strip()
    for value in df_sample["group"].dropna()
    if str(value).strip()
}
raw_group_map = []
if df_comp.empty:
    if not sample_groups:
        raise ValueError("incremental 输入没有任何有效 sample.group，无法生成临时分组。")
    raw_group_map.append(sorted(sample_groups))
    print("ℹ️ incremental 输入 comparison 为空：已按 sample.group 生成临时 group1。")
else:
    for row_index, row in df_comp.iterrows():
        comparison_name = "" if pd.isna(row.iloc[0]) else str(row.iloc[0]).strip()
        members = [
            str(value).strip()
            for value in row.iloc[1:].dropna()
            if str(value).strip()
        ]
        if not comparison_name:
            raise ValueError(f"comparison sheet 第 {row_index + 2} 行缺少比较名称。")
        if len(members) < 2:
            raise ValueError(
                f"comparison sheet 第 {row_index + 2} 行（{comparison_name}）至少需填写两个分组。"
            )
        unknown_members = sorted(set(members) - sample_groups)
        if unknown_members:
            raise ValueError(
                f"comparison sheet 第 {row_index + 2} 行（{comparison_name}）包含 sample.group 中不存在的分组: "
                f"{', '.join(unknown_members)}。当前可用分组: {', '.join(sorted(sample_groups))}"
            )
        raw_group_map.append(members)

# 下游脚本（QC_stats、tax_stats 等）期望 metadata 列名为 group1, group2...
groups = [f"group{i+1}" for i in range(len(raw_group_map))]
group_map = dict(zip(groups, raw_group_map))

# 构建元数据：使用 apply 向量化操作
def build_metadata_row(row, groups, group_map):
    sid = row["sample"]
    cat = str(row["group"])
    out_row = {"sample-id": sid}
    for g in groups:
        out_row[g] = cat if cat in group_map.get(g, []) else ""
    return out_row

metadata_rows = df_sample.apply(
    lambda row: build_metadata_row(row, groups, group_map),
    axis=1
).tolist()

df_meta = pd.DataFrame(metadata_rows)

# 添加 q2:types 行
type_row = {"sample-id": "#q2:types"}
for g in groups:
    type_row[g] = "categorical"
df_meta = pd.concat([pd.DataFrame([type_row]), df_meta], ignore_index=True)

# 保存
metadata_path = os.path.join(args.outdir, "sample-metadata.tsv")
df_meta.to_csv(metadata_path, sep="\t", index=False)

elapsed = time.time() - start_time
print(f"\n✅ 完成！耗时: {elapsed:.3f}秒")
print(f"📄 输出: {sample_path}, {metadata_path}")
