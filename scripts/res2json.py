#!/usr/bin/env python
# -*- coding: utf-8 -*-
# By: Wang Li 2024
import os
import json
import argparse
import pandas as pd
import time
import glob


# 报告信息json，格式
# {"客户名称": "SanShu", "客户单位": "Lcpart", "项目编号": "sanshu123456789", "报告时间": "2023-08-09"}
def get_businfo(datadir, respath):
    bus_info=json.load(open(os.path.join(datadir,"project_info.json"),mode='r',encoding="utf-8"))
    name = bus_info['客户名称']
    partment = bus_info['客户单位']
    NO = bus_info['项目编号']
    TI = str(time.strftime("%Y-%m-%d", time.localtime()))
    bus_dict = dict()
    bus_dict['客户名称'] = name
    bus_dict['客户单位'] = partment
    bus_dict['项目编号'] = NO
    bus_dict['报告时间'] = TI
    with open("%s/bus_info.json" % respath, "w", encoding='utf-8') as f:
        json.dump(bus_dict, f, ensure_ascii=False)


# 基础表格json，格式
# {"columns":["字段1","字段2","字段3","字段3"],"data":[["r1c1","r1c2","r1c3","r1c4"],["r2c1","r2c2","r2c3","r2c4"]]}
def get_sample(datadir, respath):
    sample = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
    sample_dict = dict()
    sample_dict['columns'] = ["样品", "分组"]
    samp_ls = sample.to_numpy().tolist()
    sample_dict['data'] = samp_ls
    with open("%s/sample_info.json" % respath, "w", encoding='utf-8') as f:
        json.dump(sample_dict, f, ensure_ascii=False)


def get_table(path, sheetname):
    if not sheetname:
        data = pd.read_excel(path)
        columns = data.columns.to_list()
        data_ls = data.to_numpy().tolist()
        dic = dict()
        dic['columns'] = columns
        dic['data'] = data_ls
        return dic
    else:
        data = pd.read_excel(path, sheet_name=sheetname)
        columns = data.columns.to_list()
        data_ls = data.to_numpy().tolist()
        dic = dict()
        dic['columns'] = columns
        dic['data'] = data_ls
        return dic


# def table2json(sorpath, despath):
# 	with open("%s/qc_stats.json" % despath, "w", encoding='utf-8') as f:
# 		main_dict = get_table(os.path.join(sorpath, '01.clean_data/qc_stats.xlsx'), False)
# 		json.dump(main_dict, f)


# 多图片2json，格式
# {
#     "isGetFileToProject":true,
#     "data":{
#         "image1":"admin_static/image/AmyloseLength/SampleChromatogram.png",
#         "image2":"admin_static/image/AmyloseLength/StandardChromatogram.png"
#     }
# }
# html的json，格式
# {
#     "isGetFileToProject":true,
#     "data":{
#         "image1":"output/1759b96e-3bbf-ebd8-3d8d-6d487eacedb3/3956267f96b4da41576fac12b6dd7369.html"
#     }
# }
def get_filenames(org_path):
    check_paths = glob.iglob(org_path)
    file_ls_h = []
    file_ls_p = []
    for ch_path in check_paths:
        g = os.walk(ch_path)
        for path, dir_list, file_list in g:
            for file in file_list:
                if file.endswith('html'):
                    file_path = os.path.abspath(os.path.join(path, file))
                    file_ls_h.append(file_path)
                elif file.endswith('png'):
                    file_path = os.path.abspath(os.path.join(path, file))
                    file_ls_p.append(file_path)
    file_ls_h = file_ls_h[0:20]
    file_ls_p = file_ls_p[0:20]
    file_ls = file_ls_h + file_ls_p
    return file_ls


def get_path_kv(path, end_chr, keyword):
    secondary_dict = dict()
    file_list = get_filenames(path)
    i = 0
    for file_path in file_list:
        i += 1
        if not keyword:
            if file_path.endswith(end_chr):
                file_name = os.path.basename(file_path) + str(i)
                secondary_dict[file_name] = file_path
        else:
            if file_path.endswith(end_chr) and keyword in file_path:
                file_name = os.path.basename(file_path) + str(i)
                secondary_dict[file_name] = file_path
    return secondary_dict


def image2json(sorpath, end_chr, keyword):
    main_dict = dict()
    main_dict['isGetFileToProject'] = True
    main_dict['data'] = dict()
    main_dict['data'] = get_path_kv(sorpath, end_chr, keyword)
    return main_dict


def get_image_json(sorpath, respath):
    with open("%s/error_rate.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/1-data_quality'), 'html', 'error_rate')
        json.dump(main_dict, f)
    with open("%s/ATGC_content.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/1-data_quality'), 'html', 'ATGC_content')
        json.dump(main_dict, f)
    with open("%s/reads_quality_summary.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/1-data_quality'), 'png', 'reads_quality_summary')
        json.dump(main_dict, f)
    with open("%s/contig_length.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/2-Assembly'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/gene_length.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/3-GenePredict'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/sample.corr_heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/4-GeneAbundance/Sample_correlation'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/upset.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/4-GeneAbundance/Venn'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/krona.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/2.Krona'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/3.Barplot/Samples'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_bar_tree.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/4.Bar_tree'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/tax_heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/5.Heatmap/Samples'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/alpha.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/7.alpha_diversity_analysis/*/'), 'html', False)
        print(main_dict)
        json.dump(main_dict, f)
    with open("%s/tax_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/6.Beta_diversity_analysis/*/*/1.PCA'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/6.Beta_diversity_analysis/*/*/2.PCoA'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/5-TaxAnnotation/6.Beta_diversity_analysis/*/*/3.NMDS'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/6-TaxStatistical_analysis/*/*/1.ANOVA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/6-TaxStatistical_analysis/*/*/2.wilcoxon'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/6-TaxStatistical_analysis/*/*/3.Stamp'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/tax_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/6-TaxStatistical_analysis/*/*/4.Random_Forest'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/6-TaxStatistical_analysis/*/*/5.metagenomeSeq'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/6-TaxStatistical_analysis/*/*/6.Anosim'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/tax_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/6-TaxStatistical_analysis/*/*/9.Lefse'), 'html', False)
        json.dump(main_dict, f)

    with open("%s/func_Barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/7-FunctionAnnotation/*/1.Barplot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/func_Heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/7-FunctionAnnotation/*/2.Heatmap'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/func_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/7-FunctionAnnotation/*/3.PCA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/func_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/7-FunctionAnnotation/*/4.PCoA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/func_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/7-FunctionAnnotation/*/5.NMDS'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/func_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/8-FunctionStatistical_analysis/*/1.ANOVA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/func_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/8-FunctionStatistical_analysis/*/2.wilcoxon'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/func_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/8-FunctionStatistical_analysis/*/3.Stamp'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/func_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/8-FunctionStatistical_analysis/*/4.Random_Forest'), 'html',
                            False)
        json.dump(main_dict, f)
    with open("%s/func_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/8-FunctionStatistical_analysis/*/5.metagenomeSeq'), 'html',
                            False)
        json.dump(main_dict, f)
    with open("%s/func_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/8-FunctionStatistical_analysis/*/6.Anosim'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/func_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/8-FunctionStatistical_analysis/*/9.Lefse'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_Barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/1.Barplot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_Heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/2.Heatmap'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/3.PCA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/4.PCoA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/5.NMDS'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/6.Statistical_test_analysis/1.ANOVA'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/6.Statistical_test_analysis/2.wilcoxon'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/9-METABOLIC/*/6.Statistical_test_analysis/3.Stamp'), 'png',
                            False)
        json.dump(main_dict, f)
    with open("%s/Cyc_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(
            os.path.join(sorpath, 'group*/9-METABOLIC/*/6.Statistical_test_analysis/4.Random_Forest'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(
            os.path.join(sorpath, 'group*/9-METABOLIC/*/6.Statistical_test_analysis/5.metagenomeSeq'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(
            os.path.join(sorpath, 'group*/9-METABOLIC/*/6.Statistical_test_analysis/6.Anosim'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Cyc_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(
            os.path.join(sorpath, 'group*/9-METABOLIC/*/6.Statistical_test_analysis/9.Lefse'), 'html', False)
        json.dump(main_dict, f)

    with open("%s/ARG_Barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/1.Barplot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_Heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/2.Heatmap'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/3.PCA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/4.PCoA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/5.NMDS'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/6.Statistical_test_analysis/1.ANOVA'), 'html',
                            False)
        json.dump(main_dict, f)
    with open("%s/ARG_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/6.Statistical_test_analysis/2.wilcoxon'), 'html',
                            False)
        json.dump(main_dict, f)
    with open("%s/ARG_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/6.Statistical_test_analysis/3.Stamp'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/ARG_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/6.Statistical_test_analysis/4.Random_Forest'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/6.Statistical_test_analysis/5.metagenomeSeq'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/6.Statistical_test_analysis/6.Anosim'),
                            'html', False)
        json.dump(main_dict, f)
    with open("%s/ARG_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/10-ARG/6.Statistical_test_analysis/9.Lefse'),
                            'html', False)
        json.dump(main_dict, f)

    with open("%s/VFDB_Barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/1.Barplot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_Heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/2.Heatmap'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/3.PCA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/4.PCoA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/5.NMDS'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/6.Statistical_test_analysis/1.ANOVA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/6.Statistical_test_analysis/2.wilcoxon'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/6.Statistical_test_analysis/3.Stamp'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/6.Statistical_test_analysis/4.Random_Forest'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/6.Statistical_test_analysis/5.metagenomeSeq'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/6.Statistical_test_analysis/6.Anosim'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/VFDB_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/11-VFDB/6.Statistical_test_analysis/9.Lefse'), 'html', False)
        json.dump(main_dict, f)


    with open("%s/mobileOG_Barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/1.Barplot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_Heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/2.Heatmap'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/3.PCA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/4.PCoA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/5.NMDS'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/6.Statistical_test_analysis/1.ANOVA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/6.Statistical_test_analysis/2.wilcoxon'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/6.Statistical_test_analysis/3.Stamp'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/6.Statistical_test_analysis/4.Random_Forest'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/6.Statistical_test_analysis/5.metagenomeSeq'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/6.Statistical_test_analysis/6.Anosim'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/mobileOG_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/12-mobileOG/6.Statistical_test_analysis/9.Lefse'), 'html', False)
        json.dump(main_dict, f)


    with open("%s/BacMet2_Barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/1.Barplot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_Heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/2.Heatmap'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/3.PCA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/4.PCoA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/5.NMDS'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/6.Statistical_test_analysis/1.ANOVA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/6.Statistical_test_analysis/2.wilcoxon'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/6.Statistical_test_analysis/3.Stamp'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/6.Statistical_test_analysis/4.Random_Forest'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/6.Statistical_test_analysis/5.metagenomeSeq'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/6.Statistical_test_analysis/6.Anosim'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/BacMet2_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/13-BacMet2/6.Statistical_test_analysis/9.Lefse'), 'html', False)
        json.dump(main_dict, f)


    with open("%s/QS_Barplot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/1.Barplot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_Heatmap.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/2.Heatmap'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_PCA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/3.PCA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_PCoA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/4.PCoA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_NMDS.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/5.NMDS'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_ANOVA.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/6.Statistical_test_analysis/1.ANOVA'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_wilcoxon.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/6.Statistical_test_analysis/2.wilcoxon'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_Stamp.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/6.Statistical_test_analysis/3.Stamp'), 'png', False)
        json.dump(main_dict, f)
    with open("%s/QS_Random_Forest.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/6.Statistical_test_analysis/4.Random_Forest'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_metagenomeSeq.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/6.Statistical_test_analysis/5.metagenomeSeq'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_Anosim.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/6.Statistical_test_analysis/6.Anosim'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/QS_Lefse.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'group*/14-QS/6.Statistical_test_analysis/9.Lefse'), 'html', False)
        json.dump(main_dict, f)

    with open("%s/Bin_Plot.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'binning/2.Bin_Plot'), 'html', False)
        json.dump(main_dict, f)
    with open("%s/Bin_Abundance.json" % respath, "w", encoding='utf-8') as f:
        main_dict = image2json(os.path.join(sorpath, 'binning/3.Bin_Abundance'), 'html', False)
        json.dump(main_dict, f)


def json_check(dest_path):
    files = os.listdir(dest_path)
    for file in files:
        with open('%s/%s' % (dest_path, file), 'r', encoding='utf-8') as f:
            dict = json.load(f)
            for k, v in dict.items():
                if k == 'data' and dict['data'] == {}:
                    print(file)
                    f.close()
                    os.remove('%s/%s' % (dest_path, file))


def main():
    parser = argparse.ArgumentParser(
        description='This script will generate otu_tax.xlsx')
    parser.add_argument('--sorc_path', type=str, required=True, help='the dir of Source path')
    parser.add_argument('-I', '--i_datadir', type=str, required=True, help='the dir of sample-metadata.tsv')
    parser.add_argument('--dest_path', type=str, default='jsonFile', help='the dir of Destination path')
    args = parser.parse_args()

    datadir = os.path.abspath(args.i_datadir)
    sorc_path = os.path.abspath(args.sorc_path)
    dest_path = os.path.abspath(args.dest_path)
    if not os.path.exists(dest_path):
        os.mkdir(dest_path)

    get_image_json(sorc_path, dest_path)
    get_businfo(datadir, dest_path)
    get_sample(datadir, dest_path)
    json_check(dest_path)


if __name__ == '__main__':
    main()
