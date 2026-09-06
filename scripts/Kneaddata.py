#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024
# 从原始数据生成cleandata，注意格式必须为
# <sample><_1/2><.format><.gz>或者<sample><_R1/R2><.format><.gz>
import os, json, argparse
import pandas as pd
import threading
import numpy as np
from get_scriptspath import scripts_path, Rscript_j


def QC(rawdatadir, datadir, cleandatadir):
    # cleandata与rawdata同级
    if not os.path.exists(os.path.join(cleandatadir, 'qc')):
        os.makedirs(os.path.join(cleandatadir, 'qc'))
    cmd = '''bash {0}/QC.sh {1} {2} {3} >qc.log 2>&1'''.format(scripts_path, rawdatadir, datadir, cleandatadir)
    os.system(cmd)


def error_rate_table(cleandatadir):
    qc_dir = os.path.join(cleandatadir, 'qc')
    res_dir = os.path.join(cleandatadir, 'table')
    if not os.path.exists(res_dir):
        os.mkdir(res_dir)
    files = os.listdir(qc_dir)
    for file in files:
        if file.endswith('.json'):
            prefix = file.split('.json')[0].strip()
            with open('%s/%s' % (qc_dir, file), 'r', encoding='utf-8') as fp:
                json_dat = json.load(fp)
                raw_quality1 = json_dat['read1_before_filtering']['quality_curves']['mean']
                raw_content1 = json_dat['read1_before_filtering']['content_curves']
                raw_quality2 = json_dat['read2_before_filtering']['quality_curves']['mean']
                raw_content2 = json_dat['read2_before_filtering']['content_curves']
                knums = len(raw_quality1)
                bp_r1 = list(range(1, knums+1))
                bp_r2 = list(range(knums+1, knums*2+1))

                raw_q1 = pd.DataFrame(list(zip(bp_r1, raw_quality1)), columns=['reads', 'Q'])
                raw_q2 = pd.DataFrame(list(zip(bp_r2, raw_quality2)), columns=['reads', 'Q'])
                raw_q1['group'] = 'Read1'
                raw_q2['group'] = 'Read2'
                raw_q = pd.concat([raw_q1, raw_q2], axis=0)
                error_rate = np.power(10, -raw_q['Q'].to_numpy() / 10)
                raw_q['error_rate'] = error_rate
                raw_q.to_csv('%s/%s_error_rate.tsv' % (res_dir, prefix), sep='\t', index=False)

                raw_c1 = pd.DataFrame(raw_content1)
                raw_c1['reads'] = bp_r1
                raw_c1['group'] = 'Read1'
                raw_c2 = pd.DataFrame(raw_content2)
                raw_c2['reads'] = bp_r2
                raw_c2['group'] = 'Read2'
                raw_c = pd.concat([raw_c1, raw_c2], axis=0)
                raw_c = raw_c.drop(['GC'], axis=1)
                raw_c.to_csv('%s/%s_content.tsv' % (res_dir, prefix), sep='\t', index=False)


def plot_table(cleandatadir, datadir, res_dir, host_dir, host):
    table_dir = os.path.join(cleandatadir, 'table')
    cmd = '''
    {0} {1}/error_rate.R {2} {3} {4}
    {0} {1}/atgc_content.R {2} {3} {4}
    '''.format(Rscript_j, scripts_path, table_dir, datadir, res_dir)
    os.system(cmd)

    if host == 'none':
        table_dir = os.path.join(cleandatadir, 'table')
    else:
        table_dir = os.path.join(host_dir, 'table')

    cmd = '''
    {0} {1}/data_composition_bar.R {2} {3} {4} {5}
    '''.format(Rscript_j, scripts_path, table_dir, datadir, res_dir, host)
    os.system(cmd)


def deHOST(cleandatadir, datadir, host, mapdir, host_dir):
    if host == 'none':
        pass
    elif host == 'human':
        host_qcdir = os.path.join(host_dir, 'qc')
        if not os.path.exists(host_qcdir):
            os.makedirs(host_qcdir)
        cmd = '''
        bash {0}/kneaddata.sh {1} {2} {3} {4} 'human_genome/hg37dec_v0.1'
        '''.format(scripts_path, datadir, mapdir, cleandatadir, host_dir)
        os.system(cmd)
    elif host == 'mouse':
        host_qcdir = os.path.join(host_dir, 'qc')
        if not os.path.exists(host_qcdir):
            os.makedirs(host_qcdir)
        cmd = '''
        bash {0}/kneaddata.sh {1} {2} {3} {4} 'mouse_C57BL_6NJ/mouse_C57BL_6NJ'
        '''.format(scripts_path, datadir, mapdir, cleandatadir, host_dir)
        os.system(cmd)
    else:
        host_qcdir = os.path.join(host_dir, 'qc')
        if not os.path.exists(host_qcdir):
            os.makedirs(host_qcdir)
        cmd = '''
        bash {0}/kneaddata.sh {1} {2} {3} {4} {5}/{5}
        '''.format(scripts_path, datadir, mapdir, cleandatadir, host_dir, host)
        os.system(cmd)



# 		cmd = '''
# source ~/anaconda3/etc/profile.d/conda.sh
# conda activate biobakery
# awk 'NR!=1 {print}' %s/sample.txt|while read id;do
#     sample=`echo ${id}|cut -d " " -f 2`
#     echo ${sample}
# 	bowtie2 -p 64 --no-unal\
# 	-x %s/mouse_C57BL_6NJ/mouse_C57BL_6NJ \
# 	-1 %s/${sample}_clean_1.fastq.gz \
# 	-2 %s/${sample}_clean_2.fastq.gz \
# 	--un-conc-gz %s/${sample}_de_host.fastq.gz
# 	mv %s/${sample}_de_host.fastq.1.gz %s/${sample}_dehost_1.fastq.gz
#     mv %s/${sample}_de_host.fastq.2.gz %s/${sample}_dehost_2.fastq.gz
# done
# rm %s/*clean.fastq.gz
# ''' % (datadir, mapdir, cleandatadir, cleandatadir, host_dir, host_dir, host_dir, host_dir, host_dir, cleandatadir)
# 		os.system(cmd)


def QC_stats(datadir, cleandatadir, res_dir, host, host_dir):
    samples = []
    with open('%s/sample.txt' % datadir, 'r', encoding='utf-8') as f:
        f.readline()
        for line in f.readlines():
            samples.append(line.split('\t')[1].strip())

    df = pd.DataFrame()
    for sample in samples:
        filename = sample + '.json'
        with open('%s/qc/%s' % (cleandatadir, filename), 'r', encoding='utf-8') as f:
            data = json.load(f)
            raw = data['summary']['before_filtering']
            clean = data['summary']['after_filtering']
            raw = pd.DataFrame(raw, index=range(0, 1))
            raw = raw.loc[:, ['total_reads', 'total_bases']]
            raw.columns = ['Raw_reads', 'Raw_bases(G)']
            clean = pd.DataFrame(clean, index=range(0, 1))
            clean = clean.loc[:, ['total_reads', 'total_bases', 'q20_rate', 'q30_rate', 'gc_content']]
            clean.columns = ['Removed_low_quality_Reads', 'Removed_Low_Qualitybases(G)', 'Q20(%)', 'Q30(%)',
                            'GC_content(%)']
            new = pd.DataFrame({'Sample_name': [sample]})
            total = pd.concat([new, raw, clean], axis=1)
            df = df._append(total)
    df['Raw_bases(G)'] = df['Raw_bases(G)'].apply(lambda x: round(x / 10 ** 9, 2))
    df['Removed_Low_Qualitybases(G)'] = df['Removed_Low_Qualitybases(G)'].apply(lambda x: round(x / 10 ** 9, 2))
    df.to_csv('%s/table/sumary.txt' % cleandatadir, sep='\t', index=False)

    if host == 'none':
        df = pd.read_csv('%s/table/sumary.txt' % cleandatadir, sep='\t', dtype={'Sample_name': str})
        sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
        k = sam_gros.shape[1]
        for i in range(1, k):
            sam_gro = sam_gros.iloc[:, [0] + [i]]
            sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
            group_num = 'group' + str(i)

            sam_df = pd.merge(left=sam_gro, right=df, left_on='sample-id', right_on='Sample_name', how='inner')
            sam_df = sam_df.drop(['sample-id', group_num], axis=1)
            sam_dir = os.path.join(res_dir, group_num, '1-data_quality')
            if not os.path.exists(sam_dir):
                os.makedirs(sam_dir)
            sam_df.to_excel('%s/data_quality.xlsx' % sam_dir, index=False)
    else:
        if not os.path.exists(os.path.join(host_dir, 'table')):
            os.mkdir(os.path.join(host_dir, 'table'))
        pre_summary = pd.read_csv('%s/table/sumary.txt' % cleandatadir, sep='\t', dtype={'Sample_name': str})
        pre_summary = pre_summary.iloc[:, 0:5]

        df = pd.DataFrame()
        files = os.listdir('%s/qc' % host_dir)
        for file in files:
            if file.endswith('.json'):
                prefix = file.split('.json')[0].strip()
                with open('%s/qc/%s' % (host_dir, file), 'r', encoding='utf-8') as fp:
                    data = json.load(fp)
                    de_host = data['summary']['before_filtering']
                    de_host = pd.DataFrame(de_host, index=range(0, 1))
                    de_host = de_host.loc[:, ['total_reads', 'total_bases', 'q20_rate', 'q30_rate', 'gc_content']]
                    de_host.columns = ['Removed_host_Reads', 'Removed_host_bases(G)', 'Q20(%)', 'Q30(%)',
                                    'GC_content(%)']
                    new = pd.DataFrame({'Sample_name': [prefix]})
                    total = pd.concat([new, de_host], axis=1)
                    df = df._append(total)
        df['Removed_host_bases(G)'] = df['Removed_host_bases(G)'].apply(lambda x: round(x / 10 ** 9, 2))
        df_merge = pd.merge(left=pre_summary, right=df, on='Sample_name')
        df_merge.to_csv('%s/table/sumary.txt' % host_dir, sep='\t', index=False)

        sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1], dtype=str)
        k = sam_gros.shape[1]
        for i in range(1, k):
            sam_gro = sam_gros.iloc[:, [0] + [i]]
            sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
            group_num = 'group' + str(i)

            sam_df = pd.merge(left=sam_gro, right=df_merge, left_on='sample-id', right_on='Sample_name', how='inner')
            sam_df = sam_df.drop(['sample-id', group_num], axis=1)
            sam_dir = os.path.join(res_dir, group_num, '1-data_quality')
            if not os.path.exists(sam_dir):
                os.makedirs(sam_dir)
            sam_df.to_excel('%s/data_quality.xlsx' % sam_dir, index=False)


def main():
    parser = argparse.ArgumentParser(
        description='This script will generate clean_data through fastp')
    parser.add_argument('-i', '--i_rawdatadir', type=str, required=True, default='rawdata', help='the dir of raw_data')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, default='data', help='the dir of sample.txt')
    # parser.add_argument('--host', type=str, required=True, choices=['none', 'human', 'mouse', 'Triticum_aestivum'],
    # 					help='the host of metagenome')
    parser.add_argument('--host', type=str, required=True, nargs='*', help='the host of metagenome')
    parser.add_argument('-o', '--output_dir', type=str, default='cleandata', help='the dir of clean_data')
    parser.add_argument('--host_dir', type=str, default='de_host', help='the dir of dehost_data')
    parser.add_argument('--resdir', type=str, default='Result', help='the resdir')
    parser.add_argument('--mapdir', type=str, default='/data/data1/wangli/database/kneaddata_database',
                        help='the dir of kneaddata_database.xlsx')
    args = parser.parse_args()

    rawdatadir = os.path.abspath(args.i_rawdatadir)
    datadir = os.path.abspath(args.i_datadir)
    cleandadir = os.path.abspath(args.output_dir)
    res_dir = os.path.abspath(args.resdir)
    mapdir = os.path.abspath(args.mapdir)
    host_dir = os.path.abspath(args.host_dir)
    host = args.host[0]

    if not os.path.exists(res_dir):
        os.mkdir(res_dir)

    t1 = threading.Thread(target=QC, args=(rawdatadir, datadir, cleandadir))
    t2 = threading.Thread(target=deHOST, args=(cleandadir, datadir, host, mapdir, host_dir))
    t3 = threading.Thread(target=error_rate_table, args=(cleandadir,))
    t4 = threading.Thread(target=QC_stats, args=(datadir, cleandadir, res_dir, host, host_dir))
    t5 = threading.Thread(target=plot_table, args=(cleandadir, datadir, res_dir, host_dir, host))
    t1.start()
    t1.join()
    t2.start()
    t3.start()
    t2.join()
    t3.join()
    t4.start()
    t4.join()
    t5.start()


if __name__ == '__main__':
    main()
