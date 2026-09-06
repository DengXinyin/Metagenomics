# os.chdir(r'D:\新建文件夹')
# #
# # gene_tpm = pd.read_excel('gene_tpm.xlsx')
# # ano_all = pd.read_csv('func.emapper.annotations', sep='\t')
# # ano_all = ano_all.rename(columns={'#query': 'GeneID', 'eggNOG_OGs': 'eggNOG', 'KEGG_ko': 'KO'})

# # eggNOG
# cog = pd.read_csv('eggNOG/cognames2003-2014.tab', sep='\t')
# cogname = pd.read_csv('eggNOG/cogfun2003-2014.tab', sep='\t')
# kog = pd.read_excel('eggNOG/kog_name.xlsx')
#
# eggNOG = ano_all.loc[:, ['GeneID', 'eggNOG']]
# eggNOG['eggNOG'] = eggNOG['eggNOG'].str.split(',').str[0]
# eggNOG['eggNOG'] = eggNOG['eggNOG'].str.split('@').str[0]
#
# eggNOG_COG_ano = pd.merge(left=eggNOG, right=cog, left_on='eggNOG', right_on='COG')
# eggNOG_COG_ano = pd.merge(left=eggNOG_COG_ano, right=cogname, left_on='category', right_on='category')
# eggNOG_COG_ano = eggNOG_COG_ano.loc[:, ['GeneID', 'eggNOG', 'description', 'category', 'category_description']]
# eggNOG_kOG_ano = pd.merge(left=eggNOG, right=kog, left_on='eggNOG', right_on='kog_ID')
# eggNOG_kOG_ano = eggNOG_kOG_ano.loc[:, ['GeneID', 'eggNOG', 'description', 'category', 'category_description']]
#
# eggNOG_ano = pd.concat([eggNOG_COG_ano, eggNOG_kOG_ano], axis=0).reset_index(drop=True)
# # eggNOG_ano.to_csv('eggNOG_annotation.tsv', sep='\t', index=False)
#
# #丰度表
# gene_tpm = pd.read_excel('gene_tpm.xlsx')
# eggNOG_tpm = pd.merge(left=eggNOG_ano, right=gene_tpm, on='GeneID')
# eggNOG_tpm.to_excel('eggNOG.tpm.xlsx', index=False)
#
# eggNOG_category = eggNOG_tpm.drop(['GeneID', 'eggNOG', 'description'], axis=1)
# eggNOG_category['category_description'] = eggNOG_category['category'].str.cat(eggNOG_category['category_description'], sep=':')
# eggNOG_category['category_description'] = eggNOG_category['category_description'].str.strip()
# eggNOG_category = eggNOG_category.drop(['category'], axis=1)
# eggNOG_category = eggNOG_category.groupby('category_description').sum()
# eggNOG_category.to_excel('eggNOG.Category.tpm.xlsx', index=True)
#
#
# # KEGG
# ko_map = pd.read_excel('KEGG/KO_map.xlsx')
# kegg_level = pd.read_csv('KEGG/kegg_level.txt', sep='\t')
#
# ko = ano_all.loc[:, ['GeneID', 'KO']]
# ko = ko[~ko['KO'].str.contains('-')]
# ko['KO'] = ko['KO'].str.split(',').str[0]
# ko['KO'] = ko['KO'].str.split('ko:').str[1]
#
# ko_anno = pd.merge(left=ko, right=ko_map, left_on='KO', right_on='ko_ID')
# ko_anno = pd.merge(left=ko_anno, right=kegg_level, on='level3_pathway_ID')
# ko_anno = ko_anno.drop(['ko_ID'], axis=1)
# ko_anno.to_csv('KEGG_annotation.tsv', sep='\t', index=False)
#
# # 丰度表
# kegg_tpm = pd.merge(left=ko_anno, right=gene_tpm, on='GeneID')
# kegg_tpm.to_excel('KEGG.tpm.xlsx', index=False)
#
# kegg_l1 = pd.concat([kegg_tpm.iloc[:, 3], kegg_tpm.iloc[:, 6:]], axis=1)
# kegg_l1 = kegg_l1.groupby('level1_pathway_name').sum()
# kegg_l1.to_excel('level1.tpm.xlsx', index=True)
# kegg_l2 = pd.concat([kegg_tpm.iloc[:, 4], kegg_tpm.iloc[:, 6:]], axis=1)
# kegg_l2 = kegg_l2.groupby('level2_pathway_name').sum()
# kegg_l2.to_excel('level2.tpm.xlsx', index=True)
#
# kegg_l3 = pd.concat([kegg_tpm.iloc[:, [2, 5]], kegg_tpm.iloc[:, 6:]], axis=1)
# kegg_l3 = kegg_l3.groupby(['level3_pathway_ID', 'level3_pathway_name']).sum()
# kegg_l3.to_excel('level3.tpm.xlsx', index=True)

# CAZy
# CAZy_dic = defaultdict(str)
# CAZy_cat = defaultdict(str)
# with open('CAZyDB.07302020.fam-activities.txt') as f:
# 	f.readline()
# 	for line in f.readlines():
# 		id = line.split('\t')[0].strip()
# 		des = line.split('\t')[1].strip()
# 		CAZy_dic[id] = des
# 		if 'GH' in id:
# 			CAZy_cat[id] = 'GH:Glycoside Hydrolases'
# 		elif 'GT' in id:
# 			CAZy_cat[id] = 'GT:Glycosyl Transferases'
# 		elif 'CBM' in id:
# 			CAZy_cat[id] = 'CBM:Carbohydrate-Binding Modules'
# 		elif 'CE' in id:
# 			CAZy_cat[id] = 'CE:Carbohydrate Esterases'
# 		elif 'PL' in id:
# 			CAZy_cat[id] = 'PL:Polysaccharide Lyases'
# 		elif 'AA' in id:
# 			CAZy_cat[id] = 'AA:AuxiliaryActivities'
# CAZy_des = pd.DataFrame.from_dict(CAZy_dic, orient='index', columns=['Description'])
# CAZy_des = CAZy_des.reset_index().rename(columns={'index': 'CAZy'})
# CAZy_cat = pd.DataFrame.from_dict(CAZy_cat, orient='index', columns=['Category'])
# CAZy_cat = CAZy_cat.reset_index().rename(columns={'index': 'CAZy'})
# print(CAZy_des)
# print(CAZy_cat)
# CAZy_map = pd.merge(left=CAZy_des, right=CAZy_cat, on='CAZy')
# print(CAZy_map)
# CAZy_map.to_csv('CAZy_map.tsv', sep='\t', index=False)

#
# CAZy_map = pd.read_csv('CAZy_map.tsv', sep='\t')
# CAZy = ano_all.loc[:, ['GeneID', 'CAZy']]
# CAZy = CAZy[~CAZy['CAZy'].str.contains('-')]
# CAZy['CAZy'] = CAZy['CAZy'].str.split(',').str[0]
# CAZy_anno = pd.merge(left=CAZy, right=CAZy_map, on='CAZy')
# # print(CAZy_anno)
#
# # 丰度表
# gene_CAZy_tpm = pd.merge(left=CAZy_anno, right=gene_tpm, on='GeneID')
# gene_CAZy_tpm.to_excel('gene.CAZy.tpm.xlsx', index=False)
#
# k = gene_CAZy_tpm.shape[1]
# CAZy_tpm = gene_CAZy_tpm.iloc[:, [1]+list(range(4, k))]
# CAZy_tpm = CAZy_tpm.groupby('CAZy').sum()
# CAZy_tpm.to_excel('CAZy.tpm.xlsx', index=True)
#
# CAZy_Category_tpm = gene_CAZy_tpm.iloc[:, 3:]
# CAZy_Category_tpm = CAZy_Category_tpm.groupby('Category').sum()
# CAZy_Category_tpm.to_excel('CAZy.Category.tpm.xlsx', index=True)


# VFID_dic = defaultdict(str)
# VFCI_dic = defaultdict(str)
# with open('VFDB.header.txt') as f:
# 	for line in f.readlines():
# 		fasta_ID = line.split(' ')[0].strip().split('>')[1]
# 		reg = re.search(r'\((VF\d{4})\).*?\((VFC\d{4})\)', line)
# 		VFID = reg.group(1)
# 		VFCID = reg.group(2)
# 		VFID_dic[fasta_ID] = VFID
# 		VFCI_dic[fasta_ID] = VFCID
# VFID_df = pd.DataFrame.from_dict(VFID_dic, orient='index', columns=['VFID'])
# VFID_df = VFID_df.reset_index().rename(columns={'index': 'fasta_ID'})
# VFCID_df = pd.DataFrame.from_dict(VFCI_dic, orient='index', columns=['VFCID'])
# VFCID_df = VFCID_df.reset_index().rename(columns={'index': 'fasta_ID'})
# VFID_adf = pd.merge(left=VFID_df, right=VFCID_df, on='fasta_ID')
# VFID_adf.to_csv('fasta2VFID.tsv', sep='\t', index=False)
#
# os.chdir(r'D:\新建文件夹')
#
# # VFDB
# VF_map = pd.read_csv('VF_map.csv')
# fasta2VF = pd.read_csv('fasta2VFID.tsv', sep='\t')
# gene_tax = pd.read_excel('gene.taxonomy.xlsx', index_col=0)
# gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
# gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
# gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]
#
# vfres = pd.read_csv('vf_anno.txt', sep='\t')
# vfres = vfres.loc[:, ['qseqid', 'sseqid', 'evalue']]
# vfres = vfres.loc[vfres.groupby('qseqid')['evalue'].idxmin()]
# vfres = pd.merge(left=vfres, right=fasta2VF, left_on='sseqid', right_on='fasta_ID')
# vf_ano = pd.merge(left=vfres, right=VF_map, on='VFID')
# vf_ano = vf_ano.loc[:, ['qseqid', 'VF_Name', 'VFcategory']]
# vf_ano = vf_ano.rename(columns={'qseqid': 'GeneID'})
# vf_ano = pd.merge(left=gene_tax, right=vf_ano, on='GeneID')
#
# # 丰度表
# gene_tpm = pd.read_excel('gene_tpm.xlsx')
# gene_vf_tpm = pd.merge(left=vf_ano, right=gene_tpm, on='GeneID')
# gene_vf_tpm.to_excel('gene.vf.tpm.xlsx', index=False)
# print(gene_vf_tpm)
# print(gene_vf_tpm.columns)
#
# k = gene_vf_tpm.shape[1]
# vf_tpm = gene_vf_tpm.iloc[:, [2]+list(range(4, k))]
# vf_tpm = vf_tpm.groupby('VF_Name').sum()
# vf_tpm.to_excel('vf.tpm.xlsx', index=True)
#
# vf_ca_tpm = gene_vf_tpm.iloc[:, 3: ]
# vf_ca_tpm = vf_ca_tpm.groupby('VFcategory').sum()
# vf_ca_tpm.to_excel('vf.category.tpm.xlsx', index=True)

# os.chdir(r'D:\新建文件夹')
# gene_tpm = pd.read_excel('gene_tpm.xlsx')
# gene_tax = pd.read_excel('gene.taxonomy.xlsx', index_col=0)
# gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
# gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
# gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]
#
# # CycDB
# CycDB_f = ['Carbon', 'Methane', 'Nitrogen', 'phosphorylation', 'Sulfur']
# for Cyc in CycDB_f:
# 	Cyc_map = pd.read_csv('diting/%s.txt' % Cyc, sep='\t')
# 	gene_ko = pd.read_excel('Annotation/KEGG/KEGG.tpm.xlsx')
# 	gene_ko = gene_ko.iloc[:, 0:2]
# 	Cyc_anno = pd.merge(left=gene_ko, right=Cyc_map, on='KO')
# 	Cyc_anno = pd.merge(left=gene_tax, right=Cyc_anno, on='GeneID')
#
# 	# 丰度表
# 	Cyc_tpm = pd.merge(left=Cyc_anno, right=gene_tpm, on='GeneID')
# 	Cyc_tpm = Cyc_tpm.drop(['Cycle'], axis=1)
# 	Cyc_tpm = Cyc_tpm.drop_duplicates()
# 	Cyc_tpm.to_excel('%s_Cycle.xlsx' % Cyc, index=False)
# 	print(Cyc_tpm)
# 	print(Cyc_tpm.columns)
#
# 	k = Cyc_tpm.shape[1]
# 	Cyc_pathway = Cyc_tpm.iloc[:, [3] + list(range(5, k))]
# 	Cyc_pathway = Cyc_pathway.groupby('Pathway').sum()
# 	Cyc_pathway.to_excel('%s_Cycle_pathway.xlsx' % Cyc, index=True)
#
# os.chdir(r'D:\新建文件夹')
# # ARGs
# ARG_map = pd.read_csv('SARG_v3.2_S_database.txt', sep='\t')
# gene_tax = pd.read_excel('gene.taxonomy.xlsx', index_col=0)
# gene_tax['taxonomy'] = [';'.join(i) for i in gene_tax.values]
# gene_tax = gene_tax.reset_index().rename(columns={'index': 'GeneID'})
# gene_tax = gene_tax.loc[:, ['GeneID', 'taxonomy']]
#
# ARGs = pd.read_csv('ARGs_anno.txt', sep='\t')
# ARGs = ARGs.loc[:, ['qseqid', 'sseqid', 'evalue']]
# ARGs = ARGs.loc[ARGs.groupby('qseqid')['evalue'].idxmin()]
# ARG_ano = pd.merge(left=ARGs, right=ARG_map, left_on='sseqid', right_on='SARG.Seq.ID')
# ARG_ano = ARG_ano.loc[:, ['qseqid', 'Type', 'ARG']]
# ARG_ano = ARG_ano.rename(columns={'qseqid': 'GeneID'})
# ARG_ano = pd.merge(left=gene_tax, right=ARG_ano, on='GeneID')
#
#
# # 丰度表
# gene_tpm = pd.read_excel('gene_tpm.xlsx')
# gene_ARG_tpm = pd.merge(left=ARG_ano, right=gene_tpm, on='GeneID')
# gene_ARG_tpm.to_excel('ARG.tpm.xlsx', index=False)
#
# k = gene_ARG_tpm.shape[1]
# ARG_cat_tpm = gene_ARG_tpm.iloc[:, [2]+list(range(4, k))]
# ARG_cat_tpm = ARG_cat_tpm.groupby('Type').sum()
# ARG_cat_tpm.to_excel('ARG.Category.tpm.xlsx', index=True)

import numpy as np

# 碱基错误率整理
# os.chdir(r'D:\新建文件夹')
# qc_dir = r'D:\新建文件夹\qc'
# files = os.listdir(qc_dir)
# for file in files:
# 	if file.endswith('.json'):
# 		prefix = file.split('.json')[0].strip()
# 		with open('%s/%s' % (qc_dir, file), 'r', encoding='utf-8') as fp:
# 			json_dat = json.load(fp)
# 			raw_quality1 = json_dat['read1_before_filtering']['quality_curves']['mean']
# 			raw_content1 = json_dat['read1_before_filtering']['content_curves']
# 			raw_quality2 = json_dat['read2_before_filtering']['quality_curves']['mean']
# 			raw_content2 = json_dat['read2_before_filtering']['content_curves']
# 			bp_r1 = list(range(1, 151))
# 			bp_r2 = list(range(151, 301))
#
# 			raw_q1 = pd.DataFrame(list(zip(bp_r1, raw_quality1)), columns=['reads', 'Q'])
# 			raw_q2 = pd.DataFrame(list(zip(bp_r2, raw_quality2)), columns=['reads', 'Q'])
# 			raw_q1['group'] = 'Read1'
# 			raw_q2['group'] = 'Read2'
# 			raw_q = pd.concat([raw_q1, raw_q2], axis=0)
# 			error_rate = np.power(10, -raw_q['Q'].to_numpy()/10)
# 			raw_q['error_rate'] = error_rate
# 			raw_q.to_csv('%s_error_rate.tsv' % prefix, sep='\t', index=False)
#
# 			raw_c1 = pd.DataFrame(raw_content1)
# 			raw_c1['reads'] = bp_r1
# 			raw_c1['group'] = 'Read1'
# 			raw_c2 = pd.DataFrame(raw_content2)
# 			raw_c2['reads'] = bp_r2
# 			raw_c2['group'] = 'Read2'
# 			raw_c = pd.concat([raw_c1, raw_c2], axis=0)
# 			raw_c = raw_c.drop(['GC'], axis=1)
# 			raw_c.to_csv('%s_content.tsv' % prefix, sep='\t', index=False)

# # 测序数据产出统计
# os.chdir(r'D:\新建文件夹')
# datadir = r'D:\新建文件夹\data'
# cleandatadir = 'D:\新建文件夹'
# res_dir = 'D:\新建文件夹'
# samples = []
# with open('%s/sample.txt' % datadir, 'r', encoding='utf-8') as f:
# 	f.readline()
# 	for line in f.readlines():
# 		samples.append(line.split('\t')[1].strip())
#
# df = pd.DataFrame()
# for sample in samples:
# 	filename = sample + '.json'
# 	with open('%s/qc/%s' % (cleandatadir, filename), 'r') as f:
# 		data = json.load(f)
# 		raw = data['summary']['before_filtering']
# 		clean = data['summary']['after_filtering']
# 		raw = pd.DataFrame(raw, index=range(0, 1))
# 		raw = raw.loc[:, ['total_reads', 'total_bases']]
# 		raw.columns = ['Raw_reads', 'Raw_bases(G)']
# 		clean = pd.DataFrame(clean, index=range(0, 1))
# 		clean = clean.loc[:, ['total_reads', 'total_bases', 'q20_rate', 'q30_rate', 'gc_content']]
# 		clean.columns = ['Removed_low_quality_Reads', 'Removed_Low_Qualitybases(G)', 'Q20(%)', 'Q30(%)', 'GC_content(%)']
# 		new = pd.DataFrame({'Sample_name': [sample]})
# 		total = pd.concat([new, raw, clean], axis=1)
# 		df = df._append(total)
# df['Raw_bases(G)'] = df['Raw_bases(G)'].apply(lambda x: round(x / 10 ** 9, 2))
# df['Removed_Low_Qualitybases(G)'] = df['Removed_Low_Qualitybases(G)'].apply(lambda x: round(x / 10 ** 9, 2))
# print(df)
# print(df.columns)
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0]+[i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group'+str(i)
# 	print(group_num)
#
# 	sam_df = pd.merge(left=sam_gro, right=df, left_on='sample-id', right_on='Sample_name', how='inner')
# 	sam_df = sam_df.drop(['sample-id', group_num], axis=1)
# 	sam_dir = os.path.join(res_dir, group_num, '1-data_quality')
# 	if not os.path.exists(sam_dir):
# 		os.mkdir(sam_dir)
# 	sam_df.to_excel('%s/data_quality.xlsx' % sam_dir, index=False)
# 	print(sam_df)
# 	print(sam_df.columns)

# # 测序结果产出统计 dehost
# os.chdir(r'D:\新建文件夹')
# pre_summary = pd.read_csv('table/sumary.txt', sep='\t')
# pre_summary = pre_summary.iloc[:, 0:5]
#
# qc_dir = r'D:\新建文件夹\qc'
# df = pd.DataFrame()
# files = os.listdir(qc_dir)
# for file in files:
# 	if file.endswith('.json'):
# 		prefix = file.split('.json')[0].strip()
# 		with open('%s/%s' % (qc_dir, file), 'r', encoding='utf-8') as fp:
# 			data =json.load(fp)
# 			de_host = data['summary']['before_filtering']
# 			de_host = pd.DataFrame(de_host, index=range(0, 1))
# 			de_host = de_host.loc[:, ['total_reads', 'total_bases', 'q20_rate', 'q30_rate', 'gc_content']]
# 			de_host.columns = ['Removed_host_Reads', 'Removed_host_bases(G)', 'Q20(%)', 'Q30(%)', 'GC_content(%)']
# 			new = pd.DataFrame({'Sample_name': [prefix]})
# 			total = pd.concat([new, de_host], axis=1)
# 			df = df._append(total)
# df['Removed_host_bases(G)'] = df['Removed_host_bases(G)'].apply(lambda x: round(x / 10 ** 9, 2))
# df_merge = pd.merge(left=pre_summary, right=df, on='Sample_name')
#
# sam_gros = pd.read_csv('data/sample-metadata.tsv', sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0]+[i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group'+str(i)
# 	print(group_num)
#
# 	sam_df = pd.merge(left=sam_gro, right=df_merge, left_on='sample-id', right_on='Sample_name', how='inner')
# 	sam_df = sam_df.drop(['sample-id', group_num], axis=1)
# 	sam_dir = os.path.join(group_num, '1-data_quality')
# 	if not os.path.exists(sam_dir):
# 		os.mkdir(sam_dir)
# 	sam_df.to_excel('%s/data_quality.xlsx' % sam_dir, index=False)
# 	print(sam_df)
# 	print(sam_df.columns)

# 组装结果统计
# os.chdir(r'D:\新建文件夹')
# stat_dir = r'D:\新建文件夹\length'
# stat_ls = list()
# files = os.listdir(stat_dir)
# for file in files:
# 	if file.endswith('_stats.txt'):
# 		prefix = file.split('_stats.txt')[0]
# 		stat_dat = pd.read_csv('%s/%s' % (stat_dir, file), sep='\t')
# 		stat_dat = stat_dat.iloc[:, list(range(0, 6)) + [8]]
# 		stat_dat.loc[:, 'filename'] = prefix
# 		stat_dat = stat_dat.rename(columns={'filename': 'sample', 'number': 'num_contigs',
# 				'total_length': 'total_length(bp)', 'shortest': 'min_length',
# 				'longest': 'max_length', 'mean_length': 'average_length', 'N50': 'N50'})
# 		stat_ls.append(stat_dat)
# statat = pd.concat(stat_ls, axis=0)
# statat.to_excel('assembly_stat.xlsx', index=False)
# print(statat)
#
# sam_gros = pd.read_csv('data/sample-metadata.tsv', sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0]+[i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group'+str(i)
# 	print(group_num)
#
# 	sam_df = pd.merge(left=sam_gro, right=statat, left_on='sample-id', right_on='sample', how='inner')
# 	sam_df = sam_df.drop(['sample-id', group_num], axis=1)
# 	grodir = os.path.join(r'D:\新建文件夹', group_num)
# 	sam_df.to_excel('%s/2-Assembly/assembly_stat.xlsx' % grodir, index=False)
# 	print(sam_df)
# 	print(sam_df.columns)

# # gene N50 信息统计
# os.chdir(r'D:\新建文件夹')
# stat_dat = pd.read_csv('unique_stats.txt', sep='\t')
# stat_dat = stat_dat.iloc[:, list(range(0, 6)) + [8]]
# stat_dat.loc[:, 'filename'] = 'unique_gene'
# stat_dat = stat_dat.rename(columns={'filename': 'ID', 'number': 'num_contigs',
# 									'total_length': 'total_length(bp)', 'shortest': 'min_length',
# 									'longest': 'max_length', 'mean_length': 'average_length', 'N50': 'N50'})
# stat_dat.to_excel('unique_gene.stat.xlsx', index=False)

# # krona
# os.chdir(r'D:\新建文件夹')
# anno_dir = r'D:\新建文件夹\Annotation'
# if not os.path.exists(os.path.join(anno_dir, 'krona')):
# 	os.mkdir(os.path.join(anno_dir, 'krona'))
# sepecies_ls = ['kingdom', 'phylum', 'class', 'order', 'family', 'tax_dat', 'species']
#
# all_dat = pd.read_excel('%s/All/All.taxonomy.xlsx' % anno_dir)
# all_dat = all_dat.drop(['GeneID'], axis=1)
# all_dat = all_dat.groupby(by=sepecies_ls, as_index=False).sum()
#
# sam_gros = pd.read_csv('data/sample-metadata.tsv', sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0]+[i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	samples = sam_gro['sample-id'].to_list()
# 	group_num = 'group'+str(i)
#
# 	gro_dat = all_dat.loc[:, sepecies_ls + samples]
# 	command_str = ''
# 	for i in range(7, gro_dat.shape[1]):
# 		sample_tax = gro_dat.iloc[:, [i] + list(range(0, 7))]
# 		sample_name = gro_dat.columns[i]
# 		sample_tax.to_csv('%s/krona/%s.txt' % (anno_dir, sample_name), sep='\t', index=False)
# 		command_str = command_str + '%s/krona/%s.txt ' % (anno_dir, sample_name)
# 	krona = 'ktImportText %s -o krona.html' % command_str
# 	with open('krona.sh', 'w', encoding='utf-8') as f:
# 		f.write(krona)
# 	cmd = 'bash krona.sh >krona.log 2>&1'
# 	os.system(cmd)

# table
# def get_general_table(anno_dir, type, datadir):
# 	sepecies_ls = ['kingdom', 'phylum', 'class', 'order', 'family', 'tax_dat', 'species']
# 	all_dat = pd.read_excel('%s/%s/%s.taxonomy.xlsx' % (anno_dir, type, type))
# 	all_dat = all_dat.drop(['GeneID'], axis=1)
# 	all_dat = all_dat.groupby(by=sepecies_ls, as_index=False).sum()
# 	sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# 	k = sam_gros.shape[1]
# 	for i in range(1, k):
# 		sam_gro = sam_gros.iloc[:, [0] + [i]]
# 		sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 		samples = sam_gro['sample-id'].to_list()
# 		group_num = 'group' + str(i)
# 		res_grodir = os.path.join(res_dir, group_num, '5-TaxAnnotation', '2.Tables', 'Samples', type)
# 		if not os.path.exists(res_grodir):
# 			os.makedirs(res_grodir)
#
# 		gro_dat = all_dat.loc[:, sepecies_ls + samples]
# 		gro_dat.to_excel('%s/%s.taxonomy.xlsx' % (res_grodir, type), index=False)
#
#
# def get_class_exp(bacteria_tpm, type, res_grodir):
# 	bacteria_rel = bacteria_tpm.iloc[:, 7:].div(bacteria_tpm.iloc[:, 7:].sum())
# 	bacteria_rel = pd.concat([bacteria_tpm.iloc[:, 0: 7], bacteria_rel], axis=1)
# 	with pd.ExcelWriter('%s/%s/%s.taxonomy.xlsx' % (res_grodir, type, type)) as writer:
# 		bacteria_tpm.to_excel(writer, sheet_name='tpm', index=False)
# 		bacteria_rel.to_excel(writer, sheet_name='relative', index=False)
# 	for i in range(0, 7):
# 		name = bacteria_tpm.columns[i]
# 		bacta_tax_tpm = bacteria_tpm.iloc[:, [i] + list(range(7, len(bacteria_tpm.columns)))]
# 		bacta_tax_tpm = bacta_tax_tpm.groupby(by=name).sum()
# 		bacta_tax_rela = bacteria_rel.iloc[:, [i] + list(range(7, len(bacteria_rel.columns)))]
# 		bacta_tax_rela = bacta_tax_rela.groupby(by=name).sum()
# 		with pd.ExcelWriter('%s/%s/%s.xlsx' % (res_grodir, type, name)) as writer:
# 			bacta_tax_tpm.to_excel(writer, sheet_name='tpm', index=True)
# 			bacta_tax_rela.to_excel(writer, sheet_name='relative', index=True)
#
#
# os.chdir(r'D:\新建文件夹')
# anno_dir = r'D:\新建文件夹\Annotation'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
#
# # 所有级别,samples
# sepecies_ls = ['kingdom', 'phylum', 'class', 'order', 'family', 'tax_dat', 'species']
# all_dat = pd.read_excel('%s/All/All.taxonomy.xlsx' % anno_dir, sheet_name='tpm')
# all_dat = all_dat.drop(['GeneID'], axis=1)
# all_dat = all_dat.groupby(by=sepecies_ls, as_index=False).sum()
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	samples = sam_gro['sample-id'].to_list()
# 	group_num = 'group' + str(i)
# 	res_grodir = os.path.join(res_dir, group_num, '5-TaxAnnotation', '2.Tables', 'Samples')
# 	type_ls = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
# 	for type in type_ls:
# 		if not os.path.exists(os.path.join(res_grodir, type)):
# 			os.makedirs(os.path.join(res_grodir, type))
#
# 	all_tpm = all_dat.loc[:, sepecies_ls + samples]
# 	get_class_exp(all_tpm, 'All', res_grodir)
#
# 	# Bacteria
# 	bacteria_tpm = all_tpm[all_tpm['kingdom'] == 'k__Bacteria']
# 	get_class_exp(bacteria_tpm, 'bacteria', res_grodir)
#
# 	# Archaea
# 	Archaea_tpm = all_tpm[all_tpm['kingdom'] == 'k__Archaea']
# 	get_class_exp(Archaea_tpm, 'Archaea', res_grodir)
#
# 	# Eukaryota
# 	Fungi_tpm = all_tpm[all_tpm['kingdom'] == 'k__Eukaryota']
# 	get_class_exp(Fungi_tpm, 'Fungi', res_grodir)
#
# 	# Virus
# 	Virus_tpm = all_tpm[all_tpm['kingdom'] == 'k__Viruses']
# 	get_class_exp(Virus_tpm, 'Virus', res_grodir)
#
# # 所有级别,groups
# sepecies_ls = ['kingdom', 'phylum', 'class', 'order', 'family', 'tax_dat', 'species']
# all_dat = pd.read_excel('%s/All/All.taxonomy.xlsx' % anno_dir, sheet_name='tpm')
# all_dat = all_dat.drop(['GeneID'], axis=1)
# all_dat = all_dat.groupby(by=sepecies_ls, as_index=False).sum()
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	samples = sam_gro['sample-id'].to_list()
# 	group_num = 'group' + str(i)
# 	sam_gro_dc = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 	res_grodir = os.path.join(res_dir, group_num, '5-TaxAnnotation', '2.Tables', 'Groups')
# 	type_ls = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
# 	for type in type_ls:
# 		if not os.path.exists(os.path.join(res_grodir, type)):
# 			os.makedirs(os.path.join(res_grodir, type))
#
# 	all_tpm = all_dat.loc[:, sepecies_ls + samples]
# 	all_group = all_tpm.groupby(by=sam_gro_dc, axis=1).mean()
# 	all_group = pd.concat([all_tpm.iloc[:, 0: 7], all_group], axis=1)
# 	get_class_exp(all_group, 'All', res_grodir)
#
# 	# Bacteria
# 	bacteria_tpm = all_group[all_group['kingdom'] == 'k__Bacteria']
# 	get_class_exp(bacteria_tpm, 'bacteria', res_grodir)
#
# 	# Archaea
# 	Archaea_tpm = all_group[all_group['kingdom'] == 'k__Archaea']
# 	get_class_exp(Archaea_tpm, 'Archaea', res_grodir)
#
# 	# Eukaryota
# 	Fungi_tpm = all_group[all_group['kingdom'] == 'k__Eukaryota']
# 	get_class_exp(Fungi_tpm, 'Fungi', res_grodir)
#
# 	# Virus
# 	Virus_tpm = all_group[all_group['kingdom'] == 'k__Viruses']
# 	get_class_exp(Virus_tpm, 'Virus', res_grodir)

# # tax 的差异分析， anova分析
# import os, argparse, shutil
# import scipy.stats as stats
# import pandas as pd
# from statsmodels.stats import multitest

# def anova(tax_dat, sam_gro, group_num):
# 	tax_dat = tax_dat.dropna(axis=1)
# 	tax_dat = tax_dat[tax_dat.apply(lambda row: len(set(row)) != 2, axis=1)].reset_index(drop=True)
# 	k = len(sam_gro.iloc[:, 1].unique()) + 1  # 组数
# 	n = sam_gro.iloc[:, 1].value_counts()  # 样本数
# 	n = min(n.to_numpy())
# 	if not tax_dat.empty and k > 1 and n > 2:
# 		group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 		groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
# 		F_statistic, pVal = stats.f_oneway(*groups_array, axis=1)
# 		padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
# 		F_statistic = pd.Series(F_statistic).rename('F_value')
# 		pVal = pd.Series(pVal).rename('p_value')
# 		padj = pd.Series(padj).rename('padj')
# 		tax_dat_p = pd.concat([tax_dat, F_statistic, pVal, padj], axis=1)
# 		tax_dat_sign_pvalue = tax_dat_p[tax_dat_p['p_value'] < 0.05]
# 		return tax_dat_p, tax_dat_sign_pvalue
#
#
# tpmdir = r'D:\新建文件夹\tax_diff'
# table_dir = r'D:\新建文件夹\Result'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
#
#
# species = ['phylum', 'class', 'order', 'family', 'genus', 'species']
# classes = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
#
# 	for clas in classes:
# 		tax_dir = os.path.join(table_dir, group_num, '5-TaxAnnotation', '1.Tables', 'Samples', clas)
# 		for specie in species:
#
# 			tpm_taxdir = os.path.join(tpmdir, group_num, 'anova', clas)
# 			if not os.path.exists(tpm_taxdir):
# 				os.makedirs(tpm_taxdir)
# 			resdir = os.path.join(res_dir, group_num, '6-TaxStatistical_analysis', clas, specie, '1.ANOVA')
# 			if not os.path.exists(resdir):
# 				os.makedirs(resdir)
#
# 			tax_dat = pd.read_excel('%s/%s.xlsx' % (tax_dir, specie), sheet_name='tpm')
# 			res = anova(tax_dat, sam_gro)
# 			if res:
# 				genus_p, genus_sign_pvalue = res
# 				if not genus_sign_pvalue.empty:
# 					genus_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_taxdir, specie), sep='\t', index=False)
# 					with pd.ExcelWriter('%s/anova.xlsx' % resdir) as writer:
# 						genus_p.to_excel(writer, sheet_name='%s_anova' % specie, index=False)
# 						genus_sign_pvalue.to_excel(writer, sheet_name='%s_sign' % specie, index=False)
# 				else:
# 					genus_p.to_excel('%s/anova.xlsx' % resdir,
# 									 sheet_name='%s_anova' % specie, index=False)
#
# # wilcox
# def kw_wilcoxon(tax_dat, sam_gro, group_num):
# 	tax_dat = tax_dat.dropna(axis=1)
# 	tax_dat = tax_dat[tax_dat.apply(lambda row: len(set(row)) != 2, axis=1)].reset_index(drop=True)
# 	k = len(sam_gro.iloc[:, 1].unique())  # 组数
# 	n = sam_gro.iloc[:, 1].value_counts()  # 样本数
# 	n = min(n.to_numpy())
# 	if not tax_dat.empty and k == 2 and n > 1:
# 		group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 		groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
# 		statistic, pVal = stats.ranksums(*groups_array, axis=1)
# 		padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
# 		statistic = pd.Series(statistic).rename('statistic')
# 		pVal = pd.Series(pVal).rename('p_value')
# 		padj = pd.Series(padj).rename('padj')
# 		tax_dat_p = pd.concat([tax_dat, statistic, pVal, padj], axis=1)
# 		tax_dat_sign = tax_dat_p[tax_dat_p['p_value'] < 0.05]
# 		return tax_dat_p, tax_dat_sign
# 	elif not tax_dat.empty and k > 2 and n > 2:
# 		group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 		groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
# 		H_statistic, pVal = stats.kruskal(*groups_array, axis=1)
# 		padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
# 		H_statistic = pd.Series(H_statistic).rename('statistic')
# 		pVal = pd.Series(pVal).rename('p_value')
# 		padj = pd.Series(padj).rename('padj')
# 		tax_dat_p = pd.concat([tax_dat, H_statistic, pVal, padj], axis=1)
# 		tax_dat_sign = tax_dat_p[tax_dat_p['p_value'] < 0.05]
# 		return tax_dat_p, tax_dat_sign
#
# tpmdir = r'D:\新建文件夹\tax_diff'
# table_dir = r'D:\新建文件夹\Result'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'


# species = ['phylum', 'class', 'order', 'family', 'genus', 'species']
# classes = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
#
# 	for clas in classes:
# 		tax_dir = os.path.join(table_dir, group_num, '5-TaxAnnotation', '1.Tables', 'Samples', clas)
# 		for specie in species:
# 			tpm_taxdir = os.path.join(tpmdir, group_num, 'wilcoxon', clas)
# 			if not os.path.exists(tpm_taxdir):
# 				os.makedirs(tpm_taxdir)
# 			resdir = os.path.join(res_dir, group_num, '6-TaxStatistical_analysis', clas, specie, '9.Lefse')
# 			if not os.path.exists(resdir):
# 				os.makedirs(resdir)
#
# 			tax_dat = pd.read_excel('%s/%s.xlsx' % (tax_dir, specie), sheet_name='relative')
# 			res = kw_wilcoxon(tax_dat, sam_gro, group_num)
# 			if res:
# 				kww_p, kww_sign_pvalue = res
# 				if not kww_sign_pvalue.empty:
# 					kww_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_taxdir, specie), sep='\t', index=False)
# 					with pd.ExcelWriter('%s/wilcoxon.xlsx' % resdir) as writer:
# 						kww_p.to_excel(writer, sheet_name='%s_wilcoxon' % specie, index=False)
# 						kww_sign_pvalue.to_excel(writer, sheet_name='%s_sign' % specie, index=False)
# 				else:
# 					kww_p.to_excel('%s/wilcoxon.xlsx' % resdir,
# 									 sheet_name='%s_wilcoxon' % specie, index=False)

# lefse分析
# tpmdir = r'D:\新建文件夹\tax_diff'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
#
# classes = ['All', 'Archaea', 'bacteria', 'Fungi', 'Virus']
# species = ['phylum', 'class', 'order', 'family', 'genus', 'species']
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	group_num = 'group' + str(i)
# 	for clas in classes:
# 		tpm_dir = os.path.join(tpmdir, group_num, 'lefse', clas)
# 		for specie in species:
# 			resdir = os.path.join(res_dir, group_num, '6-TaxStatistical_analysis', clas, specie, '9.Lefse')
# 			if not os.path.exists(resdir):
# 				os.makedirs(resdir)
# 			res = pd.read_csv('%s/%s.res' % (tpm_dir, specie), sep='\t', header=None)
# 			res.columns = ['Taxonomy', 'Mean', 'Group', 'LDA', 'Pvalue']
# 			res = res.dropna(subset=['Group'])
# 			if not res.empty:
# 				print('{0}/LDA.xlsx'.format(resdir))
# 				res.to_csv('%s/%s_LDA.tsv' % (tpm_dir, specie), sep='\t', index=False)
# 				res.to_excel('{0}/LDA.xlsx'.format(resdir), index=False,
# 							 sheet_name='LDA_score')


# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
# 	group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
#
# 	for clas in classes:
# 		tax_dir = os.path.join(res_dir, group_num, '5-TaxAnnotation', '1.Tables', 'Samples', clas)
# 		tpm_dir = os.path.join(tpmdir, group_num, 'lefse', clas)
# 		if not os.path.exists(tpm_dir):
# 			os.makedirs(tpm_dir)
# 		for specie in species:
# 			tax_dat = pd.read_excel('%s/%s.xlsx' % (tax_dir, specie), sheet_name='tpm')
# 			tax_dat = tax_dat.rename(columns=group_dic)
# 			tax_dat = tax_dat.rename(columns={specie: 'group'})
# 			tax_dat.to_csv('%s/%s.tsv' % (tpm_dir, specie), sep='\t', index=False)

# # func_table
# anno_dir = r'D:\新建文件夹\Annotation'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
#
# # KEGG
# kegg_tpm_all = pd.read_excel('%s/KEGG/KEGG.tpm.xlsx' % anno_dir)
# eggNOG_tpm_all = pd.read_excel('%s/eggNOG/eggNOG.tpm.xlsx' % anno_dir)
# gene_CAZy_tpm_all = pd.read_excel('%s/CAZy/gene.CAZy.tpm.xlsx' % anno_dir)
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
# 	group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 	samples_ls = sam_gro.loc[:, 'sample-id'].to_list()
#
# 	resdir = os.path.join(res_dir, group_num, '7-FunctionAnnotation')
# 	tax_cla = ['1.KEGG', '2.eggNOG', '3.CAZy']
# 	for cla in tax_cla:
# 		cla_dir = os.path.join(resdir, cla)
# 		if not os.path.exists(cla_dir):
# 			os.makedirs(cla_dir)
#
# 	# kegg
# 	kegg_tpm = pd.concat([kegg_tpm_all.iloc[:, 0:6], kegg_tpm_all.loc[:, samples_ls]], axis=1)
# 	kegg_tpm.to_excel('%s/1.KEGG/KEGG.tpm.xlsx' % resdir, index=False)
# 	kegg_l1 = pd.concat([kegg_tpm.iloc[:, 3], kegg_tpm.iloc[:, 6:]], axis=1)
# 	kegg_l1 = kegg_l1.groupby('level1_pathway_name').sum()
# 	kegg_l1_gro = kegg_l1.groupby(by=group_dic, axis=1).mean()
# 	with pd.ExcelWriter('%s/1.KEGG/level1.tpm.xlsx' % resdir) as writer:
# 		kegg_l1.to_excel(writer, sheet_name='samples', index=True)
# 		kegg_l1_gro.to_excel(writer, sheet_name='group', index=True)
#
# 	kegg_l2 = pd.concat([kegg_tpm.iloc[:, 4], kegg_tpm.iloc[:, 6:]], axis=1)
# 	kegg_l2 = kegg_l2.groupby('level2_pathway_name').sum()
# 	kegg_l2_gro = kegg_l2.groupby(by=group_dic, axis=1).mean()
# 	with pd.ExcelWriter('%s/1.KEGG/level2.tpm.xlsx' % resdir) as writer:
# 		kegg_l2.to_excel(writer, sheet_name='samples', index=True)
# 		kegg_l2_gro.to_excel(writer, sheet_name='group', index=True)
#
# 	kegg_l3 = pd.concat([kegg_tpm.iloc[:, [2, 5]], kegg_tpm.iloc[:, 6:]], axis=1)
# 	kegg_l3 = kegg_l3.groupby(['level3_pathway_ID', 'level3_pathway_name'], as_index=False).sum()
# 	print(kegg_l3)
# 	print(kegg_l3.iloc[:, 1:])
# 	kegg_l3_gro = kegg_l3.groupby(by=group_dic, axis=1).mean()
# 	with pd.ExcelWriter('%s/1.KEGG/level3.tpm.xlsx' % resdir) as writer:
# 		kegg_l3.to_excel(writer, sheet_name='samples', index=True)
# 		kegg_l3_gro.to_excel(writer, sheet_name='group', index=True)
#
# 	# eggNOG
# 	eggNOG_tpm = pd.concat([eggNOG_tpm_all.iloc[:, 0:5], eggNOG_tpm_all.loc[:, samples_ls]], axis=1)
# 	eggNOG_tpm.to_excel('%s/2.eggNOG/eggNOG.tpm.xlsx' % resdir, index=False)
# 	eggNOG_category = eggNOG_tpm.drop(['GeneID', 'eggNOG', 'description'], axis=1)
# 	eggNOG_category['category_description'] = eggNOG_category['category'].str.cat(
# 		eggNOG_category['category_description'], sep=':')
# 	eggNOG_category['category_description'] = eggNOG_category['category_description'].str.strip()
# 	eggNOG_category = eggNOG_category.drop(['category'], axis=1)
# 	eggNOG_category = eggNOG_category.groupby('category_description').sum()
# 	eggNOG_ct_gro = eggNOG_category.groupby(by=group_dic, axis=1).mean()
# 	with pd.ExcelWriter('%s/2.eggNOG/eggNOG.Category.tpm.xlsx' % resdir) as writer:
# 		eggNOG_category.to_excel(writer, sheet_name='samples', index=True)
# 		eggNOG_ct_gro.to_excel(writer, sheet_name='group', index=True)
# #
# 	# CAZy
# 	gene_CAZy_tpm = pd.concat([gene_CAZy_tpm_all.iloc[:, 0:4], gene_CAZy_tpm_all.loc[:, samples_ls]], axis=1)
# 	gene_CAZy_tpm.to_excel('%s/3.CAZy/gene.CAZy.tpm.xlsx' % resdir, index=False)
#
# 	k = gene_CAZy_tpm.shape[1]
# 	CAZy_tpm = gene_CAZy_tpm.iloc[:, [1] + list(range(4, k))]
# 	CAZy_tpm = CAZy_tpm.groupby('CAZy').sum()
# 	CAZy_tpm_gro = CAZy_tpm.groupby(by=group_dic, axis=1).mean()
# 	with pd.ExcelWriter('%s/3.CAZy/CAZy.tpm.xlsx' % resdir) as writer:
# 		CAZy_tpm.to_excel(writer, sheet_name='samples', index=True)
# 		CAZy_tpm_gro.to_excel(writer, sheet_name='group', index=True)
#
# 	CAZy_Category_tpm = gene_CAZy_tpm.iloc[:, 3:]
# 	CAZy_Category_tpm = CAZy_Category_tpm.groupby('Category').sum()
# 	CAZy_Ca_tpm_gro = CAZy_Category_tpm.groupby(by=group_dic, axis=1).mean()
# 	with pd.ExcelWriter('%s/3.CAZy/CAZy.Category.tpm.xlsx' % resdir) as writer:
# 		CAZy_Category_tpm.to_excel(writer, sheet_name='samples', index=True)
# 		CAZy_Ca_tpm_gro.to_excel(writer, sheet_name='group', index=True)

# # CycDB
# CycDB_dir = r'D:\新建文件夹\CycDB'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
# 	group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 	samples_ls = sam_gro.loc[:, 'sample-id'].to_list()
#
# 	CycDB_f = ['Carbon', 'Methane', 'Nitrogen', 'phosphorylation', 'Sulfur']
# 	for Cyc in CycDB_f:
# 		Cyc_tpm = pd.read_excel('%s/%s_Cycle.xlsx' % (CycDB_dir, Cyc))
# 		Cyc_tpm = pd.concat([Cyc_tpm.iloc[:, 0:5], Cyc_tpm.loc[:, samples_ls]], axis=1)
# 		gro_t = Cyc_tpm.groupby(by=group_dic, axis=1).mean()
# 		Cyc_tpm_gro = pd.concat([Cyc_tpm.iloc[:, 0:5], gro_t], axis=1)
# 		Cyc_pathway = pd.read_excel('%s/%s_Cycle_pathway.xlsx' % (CycDB_dir, Cyc))
# 		Cyc_pathway = pd.concat([Cyc_pathway.iloc[:, [0]], Cyc_pathway.loc[:, samples_ls]], axis=1)
# 		gro_tp = Cyc_pathway.groupby(by=group_dic, axis=1).mean()
# 		Cyc_pathway_gro = pd.concat([Cyc_pathway.iloc[:, [0]], gro_tp], axis=1)
#
# 		resdir = os.path.join(res_dir, group_num, '9-METABOLIC', '%s_Cycle' % Cyc)
# 		if not os.path.exists(resdir):
# 			os.makedirs(resdir)
# 		with pd.ExcelWriter('%s/%s_Cycle.xlsx' % (resdir, Cyc)) as writer:
# 			Cyc_tpm.to_excel(writer, sheet_name='samples', index=False)
# 			Cyc_tpm_gro.to_excel(writer, sheet_name='group', index=False)
# 		with pd.ExcelWriter('%s/%s_Cycle_pathway.xlsx' % (resdir, Cyc)) as writer:
# 			Cyc_pathway.to_excel(writer, sheet_name='samples', index=False)
# 			Cyc_pathway_gro.to_excel(writer, sheet_name='group', index=False)


# # ARG
# ARGdir = r'D:\新建文件夹\ARGs'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
# 	group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 	samples_ls = sam_gro.loc[:, 'sample-id'].to_list()
#
# 	resdir = os.path.join(res_dir, group_num, '10-ARG')
# 	if not os.path.exists(resdir):
# 		os.makedirs(resdir)
#
# 	gene_ARG_tpm = pd.read_excel('%s/ARG.tpm.xlsx' % ARGdir)
# 	gene_ARG_tpm = pd.concat([gene_ARG_tpm.iloc[:, 0:4], gene_ARG_tpm.loc[:, samples_ls]], axis=1)
# 	gene_ARG_tpm.to_excel('%s/gene.ARG.tpm.xlsx' % resdir, index=False)
# 	ARG_tpm = gene_ARG_tpm.iloc[:, 3:]
# 	ARG_tpm = ARG_tpm.groupby('ARG').sum()
# 	ARG_tpm_gro = ARG_tpm.groupby(by=group_dic, axis=1).mean()
# 	k = gene_ARG_tpm.shape[1]
# 	ARG_cat_tpm = gene_ARG_tpm.iloc[:, [2] + list(range(4, k))]
# 	ARG_cat_tpm = ARG_cat_tpm.groupby('Type').sum()
# 	ARG_cat_gro = ARG_cat_tpm.groupby(by=group_dic, axis=1).mean()
# 	with pd.ExcelWriter('%s/ARG.tpm.xlsx' % resdir) as writer:
# 		ARG_tpm.to_excel(writer, sheet_name='samples', index=True)
# 		ARG_tpm_gro.to_excel(writer, sheet_name='group', index=True)
# 	with pd.ExcelWriter('%s/ARG.Category.tpm.xlsx' % resdir) as writer:
# 		ARG_cat_tpm.to_excel(writer, sheet_name='samples', index=True)
# 		ARG_cat_gro.to_excel(writer, sheet_name='group', index=True)
# 	print(ARG_tpm)
# 	print(ARG_tpm.columns)
# 	print(ARG_tpm_gro)


# # VFDB
# VFDB_dir = r'D:\新建文件夹\VFDB'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
# 	group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 	samples_ls = sam_gro.loc[:, 'sample-id'].to_list()
#
# 	resdir = os.path.join(res_dir, group_num, '11-VFDB')
# 	if not os.path.exists(resdir):
# 		os.makedirs(resdir)
#
# 	gene_vf_tpm = pd.read_excel('%s/gene.vf.tpm.xlsx' % VFDB_dir)
# 	gene_vf_tpm = pd.concat([gene_vf_tpm.iloc[:, 0:4], gene_vf_tpm.loc[:, samples_ls]], axis=1)
# 	gene_vf_tpm.to_excel('%s/gene.vf.tpm.xlsx' % resdir, index=False)
#
# 	vf_tpm = pd.read_excel('%s/vf.tpm.xlsx' % VFDB_dir)
# 	vf_tpm = pd.concat([vf_tpm.iloc[:, [0]], vf_tpm.loc[:, samples_ls]], axis=1)
# 	gro_t = vf_tpm.groupby(by=group_dic, axis=1).mean()
# 	vf_tpm_gro = pd.concat([vf_tpm.iloc[:, [0]], gro_t], axis=1)
#
# 	vf_ca_tpm = pd.read_excel('%s/vf.category.tpm.xlsx' % VFDB_dir)
# 	vf_ca_tpm = pd.concat([vf_ca_tpm.iloc[:, [0]], vf_ca_tpm.loc[:, samples_ls]], axis=1)
# 	gro_tp = vf_ca_tpm.groupby(by=group_dic, axis=1).mean()
# 	vf_ca_gro = pd.concat([vf_ca_tpm.iloc[:, [0]], gro_tp], axis=1)
#
# 	with pd.ExcelWriter('%s/vf.tpm.xlsx' % resdir) as writer:
# 		vf_tpm.to_excel(writer, sheet_name='samples', index=False)
# 		vf_tpm_gro.to_excel(writer, sheet_name='group', index=False)
#
# 	with pd.ExcelWriter('%s/vf.category.tpm.xlsx' % resdir) as writer:
# 		vf_ca_tpm.to_excel(writer, sheet_name='samples', index=False)
# 		vf_ca_gro.to_excel(writer, sheet_name='group', index=False)


# # func的diff分析测试
# func_tmpdir = r'D:\新建文件夹\func_base'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
# func_diffdir = r'D:\新建文件夹\func_diff'
#
#
# def anova(tax_dat, sam_gro, group_num):
# 	tax_dat = tax_dat.dropna(axis=1)
# 	tax_dat = tax_dat[tax_dat.apply(lambda row: len(set(row)) != 2, axis=1)].reset_index(drop=True)
# 	k = len(sam_gro.iloc[:, 1].unique())  # 组数
# 	n = sam_gro.iloc[:, 1].value_counts()  # 样本数
# 	n = min(n.to_numpy())
# 	if not tax_dat.empty and k > 1 and n > 1:
# 		group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 		groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
# 		F_statistic, pVal = stats.f_oneway(*groups_array, axis=1)
# 		padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
# 		F_statistic = pd.Series(F_statistic).rename('F_value')
# 		pVal = pd.Series(pVal).rename('p_value')
# 		padj = pd.Series(padj).rename('padj')
# 		tax_dat_p = pd.concat([tax_dat, F_statistic, pVal, padj], axis=1)
# 		tax_dat_sign_pvalue = tax_dat_p[tax_dat_p['p_value'] < 0.05]
# 		return tax_dat_p, tax_dat_sign_pvalue
#
#
# func_index = ['1.KEGG', '2.eggNOG', '3.CAZy', 'Carbon_Cycle',
# 			  'Methane_Cycle', 'Nitrogen_Cycle', 'phosphorylation_Cycle',
# 			  'Sulfur_Cycle', 'ARG', 'VFDB']
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
#
# 	for func in func_index:
# 		tpm_diffdir = os.path.join(func_diffdir, group_num, 'anova', func)
# 		if not os.path.exists(tpm_diffdir):
# 			os.makedirs(tpm_diffdir)
# 		if func == '1.KEGG' or func == '2.eggNOG' or func == '3.CAZy':
# 			resdir = os.path.join(res_dir, group_num, '8-FunctionStatistical_analysis', func, '1.ANOVA')
# 		elif '_Cycle' in func:
# 			resdir = os.path.join(res_dir, group_num, '9-METABOLIC', func, '6.Statistical_test_analysis', '1.ANOVA')
# 		elif func == 'ARG':
# 			resdir = os.path.join(res_dir, group_num, '10-ARG', '6.Statistical_test_analysis', '1.ANOVA')
# 		elif func == 'VFDB':
# 			resdir = os.path.join(res_dir, group_num, '11-VFDB', '6.Statistical_test_analysis', '1.ANOVA')
# 		if not os.path.exists(resdir):
# 			os.makedirs(resdir)
#
# 		table_dir = os.path.join(func_tmpdir, group_num, func)
# 		files = os.listdir(table_dir)
# 		for file in files:
# 			if file.endswith('_diff.tsv'):
# 				prefix = file.split('_diff.tsv')[0]
# 				func_dat = pd.read_csv('%s/%s' % (table_dir, file), sep='\t')
# 				res = anova(func_dat, sam_gro, group_num)
# 				if res:
# 					genus_p, genus_sign_pvalue = res
# 					if not genus_sign_pvalue.empty:
# 						genus_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_diffdir, prefix), sep='\t', index=False)
# 						with pd.ExcelWriter('%s/anova.xlsx' % resdir) as writer:
# 							genus_p.to_excel(writer, sheet_name='anova', index=False)
# 							genus_sign_pvalue.to_excel(writer, sheet_name='sign', index=False)
# 					else:
# 						genus_p.to_excel('%s/anova.xlsx' % resdir,
# 										 sheet_name='anova', index=False)

# def kw_wilcoxon(tax_dat, sam_gro, group_num):
# 	tax_dat = tax_dat.dropna(axis=1)
# 	tax_dat = tax_dat[tax_dat.apply(lambda row: len(set(row)) != 2, axis=1)].reset_index(drop=True)
# 	k = len(sam_gro.iloc[:, 1].unique())  # 组数
# 	n = sam_gro.iloc[:, 1].value_counts()  # 样本数
# 	n = min(n.to_numpy())
# 	if not tax_dat.empty and k == 2 and n > 1:
# 		group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 		groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
# 		statistic, pVal = stats.ranksums(*groups_array, axis=1)
# 		padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
# 		statistic = pd.Series(statistic).rename('statistic')
# 		pVal = pd.Series(pVal).rename('p_value')
# 		padj = pd.Series(padj).rename('padj')
# 		tax_dat_p = pd.concat([tax_dat, statistic, pVal, padj], axis=1)
# 		tax_dat_sign = tax_dat_p[tax_dat_p['p_value'] < 0.05]
# 		return tax_dat_p, tax_dat_sign
# 	elif not tax_dat.empty and k > 2 and n > 1:
# 		group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
# 		groups_array = [value.to_numpy(dtype=float) for name, value in tax_dat.groupby(group_dic, axis=1)]
# 		H_statistic, pVal = stats.kruskal(*groups_array, axis=1)
# 		padj = multitest.fdrcorrection(pVal, alpha=0.05)[1]
# 		H_statistic = pd.Series(H_statistic).rename('statistic')
# 		pVal = pd.Series(pVal).rename('p_value')
# 		padj = pd.Series(padj).rename('padj')
# 		tax_dat_p = pd.concat([tax_dat, H_statistic, pVal, padj], axis=1)
# 		tax_dat_sign = tax_dat_p[tax_dat_p['p_value'] < 0.05]
# 		return tax_dat_p, tax_dat_sign
#
# # func的wilcoxon测试
# func_tmpdir = r'D:\新建文件夹\func_base'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
# func_diffdir = r'D:\新建文件夹\func_diff'

# func_index = ['1.KEGG', '2.eggNOG', '3.CAZy', 'Carbon_Cycle',
# 			  'Methane_Cycle', 'Nitrogen_Cycle', 'phosphorylation_Cycle',
# 			  'Sulfur_Cycle', 'ARG', 'VFDB']
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
#
# 	for func in func_index:
# 		tpm_diffdir = os.path.join(func_diffdir, group_num, 'wilcoxon', func)
# 		if not os.path.exists(tpm_diffdir):
# 			os.makedirs(tpm_diffdir)
# 		if func == '1.KEGG' or func == '2.eggNOG' or func == '3.CAZy':
# 			resdir = os.path.join(res_dir, group_num, '8-FunctionStatistical_analysis', func, '9.Lefse')
# 		elif '_Cycle' in func:
# 			resdir = os.path.join(res_dir, group_num, '9-METABOLIC', func, '6.Statistical_test_analysis', '9.Lefse')
# 		elif func == 'ARG':
# 			resdir = os.path.join(res_dir, group_num, '10-ARG', '6.Statistical_test_analysis', '9.Lefse')
# 		elif func == 'VFDB':
# 			resdir = os.path.join(res_dir, group_num, '11-VFDB', '6.Statistical_test_analysis', '9.Lefse')
# 		if not os.path.exists(resdir):
# 			os.makedirs(resdir)
#
# 		table_dir = os.path.join(func_tmpdir, group_num, func)
# 		files = os.listdir(table_dir)
# 		for file in files:
# 			if file.endswith('_diff.tsv'):
# 				prefix = file.split('_diff.tsv')[0]
# 				func_dat = pd.read_csv('%s/%s' % (table_dir, file), sep='\t')
# 				res = kw_wilcoxon(func_dat, sam_gro, group_num)
# 				if res:
# 					kww_p, kww_sign_pvalue = res
# 					if not kww_sign_pvalue.empty:
# 						kww_sign_pvalue.to_csv('%s/%s_sign.tsv' % (tpm_diffdir, prefix), sep='\t', index=False)
# 						with pd.ExcelWriter('%s/%s_wilcoxon.xlsx' % (resdir, prefix)) as writer:
# 							kww_p.to_excel(writer, sheet_name='wilcoxon', index=False)
# 							kww_sign_pvalue.to_excel(writer, sheet_name='sign', index=False)
# 					else:
# 						kww_p.to_excel('%s/%s_wilcoxon.xlsx' % (resdir, prefix),
# 									   sheet_name='wilcoxon', index=False)


# # func 的 lefse
# func_tmpdir = r'D:\新建文件夹\func_base'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
# func_diffdir = r'D:\新建文件夹\func_diff'
#
# func_index = ['1.KEGG', '2.eggNOG', '3.CAZy', 'Carbon_Cycle',
# 			  'Methane_Cycle', 'Nitrogen_Cycle', 'phosphorylation_Cycle',
# 			  'Sulfur_Cycle', 'ARG', 'VFDB']
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	sam_gro = sam_gros.iloc[:, [0] + [i]]
# 	sam_gro = sam_gro.dropna(axis=0).reset_index(drop=True)
# 	group_num = 'group' + str(i)
# 	group_dic = pd.Series(sam_gro[group_num].values, index=sam_gro['sample-id']).to_dict()
#
# 	for func in func_index:
# 		diff_dir = os.path.join(func_diffdir, group_num, 'lefse', func)
# 		if not os.path.exists(diff_dir):
# 			os.makedirs(diff_dir)
#
# 		table_dir = os.path.join(func_tmpdir, group_num, func)
# 		files = os.listdir(table_dir)
# 		for file in files:
# 			if file.endswith('_diff.tsv'):
# 				prefix = file.split('_diff.tsv')[0].strip()
# 				func_dat = pd.read_csv('%s/%s' % (table_dir, file), sep='\t')
# 				func_dat = func_dat.rename(columns=group_dic)
# 				old_name = func_dat.columns[0]
# 				func_dat = func_dat.rename(columns={old_name: 'group'})
# 				func_dat.to_csv('%s/%s.tsv' % (diff_dir, prefix), sep='\t', index=False)
#
# 				# lefse
# 				with open("lefse.sh", "w") as script:
# 					script.write('''
# 									#!/bin/bash
# 									lefse-format_input.py {0}/{1}.tsv {0}/{1}.in -c 1 -o 1000000
# 									run_lefse.py {0}/{1}.in {0}/{1}.res
# 									'''.format(diff_dir, prefix))
# 				os.system('''bash lefse.sh >lefse.log 2>&1''')

#
# # lefse
# func_tmpdir = r'D:\新建文件夹\func_base'
# res_dir = r'D:\新建文件夹\Result'
# datadir = r'D:\新建文件夹\data'
# func_diffdir = r'D:\新建文件夹\func_diff'
#
# func_index = ['1.KEGG', '2.eggNOG', '3.CAZy', 'Carbon_Cycle',
# 			  'Methane_Cycle', 'Nitrogen_Cycle', 'phosphorylation_Cycle',
# 			  'Sulfur_Cycle', 'ARG', 'VFDB']
#
# sam_gros = pd.read_csv('%s/sample-metadata.tsv' % datadir, sep='\t', skiprows=[1])
# k = sam_gros.shape[1]
# for i in range(1, k):
# 	group_num = 'group' + str(i)
# 	for func in func_index:
# 		if func == '1.KEGG' or func == '2.eggNOG' or func == '3.CAZy':
# 			resdir = os.path.join(res_dir, group_num, '8-FunctionStatistical_analysis', func, '9.Lefse')
# 		elif '_Cycle' in func:
# 			resdir = os.path.join(res_dir, group_num, '9-METABOLIC', func, '6.Statistical_test_analysis',
# 								  '9.Lefse')
# 		elif func == 'ARG':
# 			resdir = os.path.join(res_dir, group_num, '10-ARG', '6.Statistical_test_analysis', '9.Lefse')
# 		elif func == 'VFDB':
# 			resdir = os.path.join(res_dir, group_num, '11-VFDB', '6.Statistical_test_analysis', '9.Lefse')
# 		if not os.path.exists(resdir):
# 			os.makedirs(resdir)
#
# 		diff_dir = os.path.join(func_diffdir, group_num, 'lefse', func)
# 		files = os.listdir(diff_dir)
# 		for file in files:
# 			if file.endswith('.res'):
# 				prefix = file.split('.res')[0].strip()
# 				res = pd.read_csv('%s/%s' % (diff_dir, file), sep='\t', header=None)
# 				res.columns = ['Taxonomy', 'Mean', 'Group', 'LDA', 'Pvalue']
# 				res = res.dropna(subset=['Group'])
# # 				if not res.empty:
# # 					res.to_csv('%s/%s_LDA.tsv' % (diff_dir, prefix), sep='\t', index=False)
# # 					res.to_excel('{0}/{1}_LDA.xlsx'.format(resdir, prefix), index=False,
# # 								 sheet_name='LDA_score')
#
# import json
# os.chdir(r'D:\新建文件夹')
# def get_table(path, sheetname):
# 	if not sheetname:
# 		data = pd.read_excel(path)
# 		columns = data.columns.to_list()
# 		data_ls = data.to_numpy().tolist()
# 		dic = dict()
# 		dic['columns'] = columns
# 		dic['data'] = data_ls
# 		return dic
# 	else:
# 		data = pd.read_excel(path, sheet_name=sheetname)
# 		columns = data.columns.to_list()
# 		data_ls = data.to_numpy().tolist()
# 		dic = dict()
# 		dic['columns'] = columns
# 		dic['data'] = data_ls
# 		return dic
#
#
# def table2json(sorpath, despath):
# 	with open("%s/soft.json" % despath, "w", encoding='utf-8') as f:
# 		main_dict = get_table(os.path.join(sorpath, 'soft.xlsx'), False)
# 		json.dump(main_dict, f, ensure_ascii=False)
#
# table2json(r'D:\新建文件夹', r'D:\新建文件夹')


# 整理GO大表
import json
from pprint import pprint


# 读取JSON文件
# with open(r'D:\download\参考基因组及注释文件\GO\GO.json', 'r') as f:
#     data = json.load(f)

# for i, item in enumerate(data['graphs'][0]['nodes']):
#     try:
#         id = item['id']
#         description = item['meta']['definition']['val']
#         Category = item['meta']['basicPropertyValues'][0]['val']
#         print(id)
#         print(description)
#         print(Category)
#     except KeyError

# import ast
# import pandas as pd
# from tqdm import tqdm

# workdir = r'/data/data1/wangli/database/GO'
# print('start')
# # os.chdir(r'D:\download\参考基因组及注释文件\GO')
# # 创建一个空列表,用于存储提取的数据
# category_list = []
# go_id_list = []
# description_list = []

# data = pd.read_csv(r'%s/all_OG_annotations.tsv' % workdir, sep='\t')
# GO_data = data.iloc[:, 5]
# for index, rows in tqdm(GO_data.items(), desc="Processing GO_data"): 
#     rows = ast.literal_eval(rows)
#     for key, values in rows.items():
#         Category = key
#         for v in values:
#             GO_id = v[0]
#             description = v[1]
            
#             # 将数据添加到对应的列表中           
#             category_list.append(Category)
#             go_id_list.append(GO_id)
#             description_list.append(description)

# # 创建新的 DataFrame
# new_df = pd.DataFrame({
#     'Category': category_list,
#     'GO_ID': go_id_list,
#     'Description': description_list
# })

# new_df = new_df.drop_duplicates(ignore_index=True)
# new_df.to_csv('%s/GO_map.txt' % workdir, sep='\t', index=False)

# # BacMet 实验和预测数据合并
# import pandas as pd
# import os

# os.chdir(r'D:\download\参考基因组及注释文件\BacMet')

# exp = pd.read_csv('BacMet2_EXP.753.mapping.txt', sep='\t')
# pred = pd.read_csv('BacMet2_PRE.155512.mapping.txt', sep='\t')
# exp = exp.rename(columns={'BacMet_ID':'ID', 'Accession':'Accession/GenBank_ID'})
# exp["Source"] = "Experimental"
# pred = pred.rename(columns={'GI_number': 'ID', 'GenBank_ID':'Accession/GenBank_ID'})
# pred["Source"] = "Predicted"
# all = pd.concat([exp, pred], axis=0)
# all = all.fillna(value='-')
# all.to_csv('BacMet2_all.mapping.txt', sep='\t', index=False)


# QS群体感应数据库
import os
import pandas as pd

os.chdir(r'D:\download\参考基因组及注释文件\QS')
qs_dat = pd.read_excel('uniprotkb_keyword_KW_0673_2024_08_12.xlsx')
type_dict ={'AHL':
                ['AHL','acylated homoserine lactone', 'Acyl-homoserine lactone', 'acyl homoserine lactone'],
            'DKPs':['DKP','diketopiperazines'],
            'AHQs':['AHQ', '2-Alkyl-4-quinolones', 'PQS', '2-heptyl-3-hydroxy-4-quinolone', 'HHQ', '2-heptyl-4-quinolone'],
            'DSFs':['DSF','diffusible signal factors'],
            'AI-2':['AI-2','autoinducer-2'],
            'AI-3':['AI-3','autoinducer-3'],
            'AIP': ['AIP','autoinducing peptide']
            }
# typeList = ['AHL', 'AI-2', 'AI-3', 'DSF', 'AHK',
#             'PQS ', 'AIP']
qs_dat = qs_dat.fillna('-')
print(qs_dat)
qs_dat['type'] = qs_dat['Function [CC]'].apply(lambda x: 
        ', '.join([k for k, v in type_dict.items() if any(y in x for y in v)]) or 'unclear')
qs_dat.to_excel('test_keyword.xlsx')
print(qs_dat.groupby('type').count())
