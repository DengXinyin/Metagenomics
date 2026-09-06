# Legacy draft-2 platform compatibility build.
# Generated from the development-syntax incremental WDL; do not edit by hand.


workflow metage_megahit_v2_88_1_taizhou {
    String datapath="/cephfs_data/genostack_v3/genostack_php/project_data/21499/SNDF042726061801_testdata/testdata"
    String rawdatapath="/cephfs_data/genostack_v3/genostack_php/project_data/21499/SNDF042726061801_testdata/testdata"
    String host="none"
    # node1 公共数据库挂载路径；平台可按实际节点覆盖该入参。
    String mapdir="/public/nfs_data/public_file_data/metagenome-DB"
    String binning='no'
    String analyse='yes'
    String isbwa="yes"
    # node1 test-project root; production submissions may override this path.
    String project_root="/cephfs_data/genostack_v3/genostack_php/project_data/21499/SNDF042726061801_testdata"

    # full: 全部样本跑上游；incremental: 仅新增/变更样本跑上游后合并；reuse: 直接复用上游
    String run_mode="full"
    # 首次 full 运行不需要父流程；仅 reuse/incremental 时才需要提供父流程 UUID。
    # UUID 会固定拼接到 node1 的 Cromwell 执行根目录。
    String? parent_workflow_dir

    # kraken2 optional species annotation
    Boolean use_kraken2 = false
    String? kraken2_db

    # reference genome assembly / mapping / SNP calling
    # 可选：仅提供有效样本名时才启用参考组装、比对和 SNP 分支。
    String? ref_sample

    # UniFrac beta diversity
    Boolean do_unifrac = false
    String? tax_tree
    String? func_tree

    # Plot style is fixed by the Docker image default configuration.
    # No plot_* workflow inputs are exposed on the cloud-platform form.
    call choose_plot_style {
        input:
            global_font_family="Times New Roman",
            global_theme="bw",
            global_dpi="300",
            global_width="10",
            global_height="8",
            title_font_family="Times New Roman",
            title_size="24",
            title_bold="true",
            title_italic="false",
            title_align="center",
            title_show="true",
            axis_title_font_family="Times New Roman",
            axis_title_size="20",
            axis_title_bold="false",
            axis_title_italic="false",
            axis_title_align="center",
            axis_title_show="true",
            axis_text_font_family="Times New Roman",
            axis_text_size="18",
            axis_text_bold="false",
            axis_text_italic="false",
            axis_text_align="center",
            axis_text_show="true",
            legend_title_font_family="Times New Roman",
            legend_title_size="20",
            legend_title_bold="false",
            legend_title_italic="false",
            legend_title_align="left",
            legend_title_show="true",
            legend_text_font_family="Times New Roman",
            legend_text_size="18",
            legend_text_bold="false",
            legend_text_italic="false",
            legend_text_align="left",
            legend_text_show="true",
            label_font_family="Times New Roman",
            label_size="16",
            label_bold="false",
            label_italic="false",
            label_align="center",
            label_show="true",
            legend_position="right",
            legend_frame="false",
            legend_show="true",
            group_palette="#4472C4,#ED7D31,#70AD47,#A5A5A5,#FFC000,#5B9BD5,#C55A11,#8064A2,#2F5597,#A9D18E,#F4B183,#9E480E",
            task_overrides_json=write_lines(["{}"])
    }

    # 增量注册表由 WDL 内部管理，平台无需填写 registry_md5、sample_registry_tsv
    # 或 incremental_datapath。目录约定：
    #   ${project_root}/data/sample_registry.tsv
    #   ${project_root}/incremental_data/   （仅新增/变更样本的 data.xlsx）
    if (run_mode != "full") {
        call prepare_registry_context {
            input:
                project_root=project_root,
                require_incremental_data=run_mode == "incremental"
        }
    }

    if (run_mode == "full" || run_mode == "incremental"){
        call check_input_with_raw {
            input:
                dataDir=if run_mode == "incremental" then select_first([prepare_registry_context.incremental_datapath]) else datapath,
                fastq_dir=rawdatapath,
                allow_extra_fastq=run_mode == "incremental",
                allow_empty_comparison=run_mode == "incremental",
                bust_cache=prepare_registry_context.registry_md5
        }
        call kneaddata_no {
            input:
                datapath=check_input_with_raw.result,
                rawdatapath=rawdatapath,
                host=host,
                mapdir=mapdir,
                checkDir=check_input_with_raw.result,
                keep_clean_reads=use_kraken2,
                plot_style=choose_plot_style.plot_style
        }

        if (use_kraken2 && defined(kraken2_db)) {
            call kraken2_anno {
                input:
                    cleandir=kneaddata_no.cleandir,
                    datapath=check_input_with_raw.result,
                    kraken2_db=select_first([kraken2_db])
            }
            call kraken2_tax_base {
                input:
                    datapath=check_input_with_raw.result,
                    kraken2_out=kraken2_anno.kraken2_out,
                    plot_style=choose_plot_style.plot_style
            }
        }
        call megahit_no {
            input:
                datapath=check_input_with_raw.result,
                clean_dir=kneaddata_no.cleandir,
                host=host,
                dehost_dir=kneaddata_no.dohost_dir
        }

        if (binning == 'yes'){
            call bins {
                input:
                    megahit=megahit_no.megahit,
                    datapath=check_input_with_raw.result
            }
            call bins_drep {
                input:
                    binsDir=bins.binsDir,
                    datapath=check_input_with_raw.result
            }
            call quant_classify {
                input:
                    megahit=megahit_no.megahit,
                    datapath=check_input_with_raw.result,
                    host=host,
                    clean_dir=kneaddata_no.cleandir,
                    drepDir=bins_drep.drepDir
            }
            call bins_stats {
                input:
                    drepDir=bins_drep.drepDir,
                    classfiDir=quant_classify.classfiDir,
                    quantDir=quant_classify.quantDir,
                    blobologyDir=quant_classify.blobologyDir,
                    plot_style=choose_plot_style.plot_style
            }
        }

        call prodig_no {
            input:
                megahit=megahit_no.megahit,
                datapath=check_input_with_raw.result,
        }
        call bwa_no {
            input:
                prodigal=prodig_no.prodigal,
                datapath=check_input_with_raw.result,
                clean_dir=kneaddata_no.cleandir,
                host=host,
                dehost_dir=kneaddata_no.dohost_dir
        }
        call tax_anno {
            input:
                prodigal=prodig_no.prodigal,
                mapdir=mapdir,
                datapath=check_input_with_raw.result
        }
        call func_anno {
            input:
                prodigal=prodig_no.prodigal,
                mapdir=mapdir,
                datapath=check_input_with_raw.result
        }
        if (defined(ref_sample) && select_first([ref_sample]) != "") {
            call ref_assembly {
                input:
                    datapath=check_input_with_raw.result,
                    cleandir=kneaddata_no.cleandir,
                ref_sample=select_first([ref_sample])
            }
            call ref_mapping {
                input:
                    datapath=check_input_with_raw.result,
                    cleandir=kneaddata_no.cleandir,
                    ref_fasta=ref_assembly.ref_fasta
            }
            call snp_calling {
                input:
                    datapath=check_input_with_raw.result,
                    bamdir=ref_mapping.ref_mapping_dir,
                    ref_fasta=ref_assembly.ref_fasta,
                    plot_style=choose_plot_style.plot_style
            }
        }
    }

    if(run_mode != "full"){
        call check_input_no_raw {
            input:
                dataDir=datapath,
                bust_cache=prepare_registry_context.registry_md5
        }
        call deal_parameter {
            input:
                workflow_dir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit_v2_88_1_taizhou/" + select_first([parent_workflow_dir])
        }
    }

    if (run_mode == "incremental") {
        call merge_upstream_results {
            input:
                old_clean=select_first([deal_parameter.clean_dir]),
                new_clean=select_first([kneaddata_no.cleandir]),
                old_qc=select_first([deal_parameter.kneaddatadir]),
                new_qc=select_first([kneaddata_no.Result]),
                old_megahit=select_first([deal_parameter.megahitdir]),
                new_megahit=select_first([megahit_no.megahit]),
                old_prodigal=select_first([deal_parameter.prodigdir]),
                new_prodigal=select_first([prodig_no.prodigal]),
                old_bowtie=select_first([deal_parameter.bwadir]),
                new_bowtie=select_first([bwa_no.bowtie]),
                old_tax_annotation=select_first([deal_parameter.tax_annodir]),
                new_tax_annotation=select_first([tax_anno.tax_Annotation]),
                old_func_annotation=select_first([deal_parameter.func_annodir]),
                new_func_annotation=select_first([func_anno.func_Annotation])
        }
    }

    # full/incremental 都在完整的上游集合上重建汇总注释；reuse 直接使用历史汇总结果。
    if (run_mode != "reuse") {
        call anno {
            input:
                bowtie=select_first([merge_upstream_results.bowtie, bwa_no.bowtie]),
                tax_Annotation=select_first([merge_upstream_results.tax_annotation, tax_anno.tax_Annotation]),
                func_Annotation=select_first([merge_upstream_results.func_annotation, func_anno.func_Annotation]),
                mapdir=mapdir,
                datapath=select_first([check_input_no_raw.result, check_input_with_raw.result])
        }
        call VCA_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=select_first([merge_upstream_results.prodigal, prodig_no.prodigal]),
                bowtie=select_first([merge_upstream_results.bowtie, bwa_no.bowtie]),
                mapdir=mapdir,
                datapath=select_first([check_input_no_raw.result, check_input_with_raw.result])
        }
        call MBQ_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=select_first([merge_upstream_results.prodigal, prodig_no.prodigal]),
                bowtie=select_first([merge_upstream_results.bowtie, bwa_no.bowtie]),
                mapdir=mapdir,
                datapath=select_first([check_input_no_raw.result, check_input_with_raw.result])
        }
        call COG_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=select_first([merge_upstream_results.prodigal, prodig_no.prodigal]),
                bowtie=select_first([merge_upstream_results.bowtie, bwa_no.bowtie]),
                mapdir=mapdir,
                datapath=select_first([check_input_no_raw.result, check_input_with_raw.result])
        }
        call MetaCyc_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=select_first([merge_upstream_results.prodigal, prodig_no.prodigal]),
                bowtie=select_first([merge_upstream_results.bowtie, bwa_no.bowtie]),
                mapdir=mapdir,
                datapath=select_first([check_input_no_raw.result, check_input_with_raw.result])
        }
    }

    call apply_registry {
        input:
            # incremental/reuse 必须优先使用当前完整 data.xlsx 生成的 metadata；
            # check_input_with_raw 在 incremental 模式中只包含新增样本。
            datapath=select_first([check_input_no_raw.result, check_input_with_raw.result]),
            registry_tsv=prepare_registry_context.registry_tsv,
            registry_md5=prepare_registry_context.registry_md5
    }

    call tax_base {
        input:
            megahit=select_first([merge_upstream_results.megahit, megahit_no.megahit,deal_parameter.megahitdir]),
            datapath=apply_registry.new_datapath,
            prodigal=select_first([merge_upstream_results.prodigal, prodig_no.prodigal, deal_parameter.prodigdir]),
            bowtie=select_first([merge_upstream_results.bowtie, bwa_no.bowtie, deal_parameter.bwadir]),
            Annotation=select_first([anno.Annotation, deal_parameter.anno_dir]),
            plot_style=choose_plot_style.plot_style
    }

    call func_base {
        input:
            datapath=apply_registry.new_datapath,
            mapdir=mapdir,
            Annotation=select_first([anno.Annotation, deal_parameter.anno_dir]),
            CycDB=select_first([VCA_anno.CycDB, deal_parameter.CycDBdir]),
            ARGdir=select_first([VCA_anno.ARGdir, deal_parameter.ARGsdir]),
            VFDB=select_first([VCA_anno.VFDB, deal_parameter.VFDBdir]),
            mobileOGs=select_first([MBQ_anno.mobileOGs, deal_parameter.mobileOG_annodir]),
            BacMet2=select_first([MBQ_anno.BacMet2, deal_parameter.BacMet2_annodir]),
            QS=select_first([MBQ_anno.QS, deal_parameter.QS_annodir]),
            COG=select_first([COG_anno.COG, deal_parameter.COGdir]),
            MetaCyc=select_first([MetaCyc_anno.MetaCyc, deal_parameter.MetaCycdir]),
            plot_style=choose_plot_style.plot_style
    }

    if (analyse == 'yes'){
        call tax_diff {
            input:
                datapath=apply_registry.new_datapath,
                preResdir=tax_base.Result,
                Annotation=select_first([anno.Annotation, deal_parameter.anno_dir]),
                plot_style=choose_plot_style.plot_style
        }
        if (use_kraken2 && defined(kraken2_db) && run_mode == "full") {
            call kraken2_tax_diff {
                input:
                    datapath=apply_registry.new_datapath,
                    preResdir=select_first([kraken2_tax_base.Result]),
                    plot_style=choose_plot_style.plot_style
            }
        }
        call func_diff {
            input:
                datapath=apply_registry.new_datapath,
                funcBase=func_base.funcBase,
                plot_style=choose_plot_style.plot_style
        }

        if (do_unifrac && defined(tax_tree)) {
            call tax_unifrac {
                input:
                    datapath=apply_registry.new_datapath,
                    tax_tree=select_first([tax_tree]),
                    resdir=tax_base.Result,
                    plot_style=choose_plot_style.plot_style
            }
        }
        if (do_unifrac && defined(func_tree)) {
            call func_unifrac {
                input:
                    datapath=apply_registry.new_datapath,
                    func_tree=select_first([func_tree]),
                    funcBase=func_base.funcBase,
                    plot_style=choose_plot_style.plot_style
            }
        }
        if (binning == 'yes'){
            call coll_res_ana_bins {
                input:
                    datapath=apply_registry.new_datapath,
                    analyse=analyse,
                    binning=binning,
                    Res1=select_first([merge_upstream_results.qc_result, kneaddata_no.Result,deal_parameter.kneaddatadir]),
                    Res2=tax_base.Result,
                    Res3=func_base.Result,
                    Res4=tax_diff.Result,
                    Res5=func_diff.Result,
                    Res6=select_first([bins_stats.Result,deal_parameter.bins_stats_dir]),
                    display_name_map=apply_registry.display_name_map,
                    host=host,
                    qc_cleandir=select_first([merge_upstream_results.clean_dir, kneaddata_no.cleandir, deal_parameter.clean_dir]),
                    plot_style=choose_plot_style.plot_style
            }
        }
        if (binning == 'no'){
            call coll_res_ana {
                input:
                    datapath=apply_registry.new_datapath,
                    analyse=analyse,
                    binning=binning,
                    Res1=select_first([merge_upstream_results.qc_result, kneaddata_no.Result,deal_parameter.kneaddatadir]),
                    Res2=tax_base.Result,
                    Res3=func_base.Result,
                    Res4=tax_diff.Result,
                    Res5=func_diff.Result,
                    display_name_map=apply_registry.display_name_map,
                    host=host,
                    qc_cleandir=select_first([merge_upstream_results.clean_dir, kneaddata_no.cleandir, deal_parameter.clean_dir]),
                    plot_style=choose_plot_style.plot_style
            }
        }
    }

    if (analyse == 'no') {
        call coll_res_NOana {
            input:
                datapath=apply_registry.new_datapath,
                analyse=analyse,
                binning=binning,
                Res1=select_first([merge_upstream_results.qc_result, kneaddata_no.Result,deal_parameter.kneaddatadir]),
                Res2=tax_base.Result,
                Res3=func_base.Result,
                display_name_map=apply_registry.display_name_map,
                host=host,
                qc_cleandir=select_first([merge_upstream_results.clean_dir, kneaddata_no.cleandir, deal_parameter.clean_dir]),
                plot_style=choose_plot_style.plot_style
        }
    }

    call res2json {
        input:
            res_dir=select_first([coll_res_ana.Result, coll_res_NOana.Result, coll_res_ana_bins.Result]),
            datapath=apply_registry.new_datapath
    }

    call resFile {
        input:
            report_no=select_first([check_input_with_raw.report_no, check_input_no_raw.report_no]),
            projectinfo=select_first([check_input_with_raw.project_info, check_input_no_raw.project_info]),
            res_dir=select_first([coll_res_ana.Result, coll_res_NOana.Result, coll_res_ana_bins.Result])
    }

    # 每次成功运行后自动更新项目级 registry，供下一次 reuse/incremental 使用。
    call update_registry {
        input:
            registry_tsv_path="${project_root}/data/sample_registry.tsv",
            project_info=select_first([check_input_with_raw.project_info, check_input_no_raw.project_info]),
            workflow_success_marker=resFile.PDFpath
    }

    output {
        File respath = resFile.respath
        File pdfFile = resFile.PDFpath
        File docxpath = resFile.docxpath
        File jsonpath = res2json.jsonFile
        File reportNo = resFile.reportNOdir
        File infoFile = resFile.project_info
        File? kraken2_out = kraken2_anno.kraken2_out
        File? kraken2_tax_base_result = kraken2_tax_base.Result
        File? kraken2_tax_diff_result = kraken2_tax_diff.Result
        File? ref_assembly_dir = ref_assembly.ref_assembly_dir
        File? ref_mapping_dir = ref_mapping.ref_mapping_dir
        File? snp_dir = snp_calling.snp_dir
        File? tax_unifrac_out = tax_unifrac.tax_unifrac_out
        File? func_unifrac_out = func_unifrac.func_unifrac_out
    }
}
task deal_parameter{
    String workflow_dir


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task deal_parameter"
        echo "Passing parameters from full parent workflow"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task deal_parameter"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        File clean_dir = "${workflow_dir}/call-kneaddata_no/execution/cleandata"
        File megahitdir = "${workflow_dir}/call-megahit_no/execution/megahit"
        File prodigdir = "${workflow_dir}/call-prodig_no/execution/prodigal"
        File bwadir = "${workflow_dir}/call-bwa_no/execution/bowtie"
        File func_annodir = "${workflow_dir}/call-func_anno/execution/Annotation"
        File anno_dir = "${workflow_dir}/call-anno/execution/Annotation"
        File tax_annodir = "${workflow_dir}/call-tax_anno/execution/Annotation"
        File ARGsdir = "${workflow_dir}/call-VCA_anno/execution/ARGs"
        File CycDBdir = "${workflow_dir}/call-VCA_anno/execution/CycDB"
        File VFDBdir = "${workflow_dir}/call-VCA_anno/execution/VFDB"
        File BacMet2_annodir = "${workflow_dir}/call-MBQ_anno/execution/BacMet2"
        File QS_annodir = "${workflow_dir}/call-MBQ_anno/execution/QS"
        File mobileOG_annodir = "${workflow_dir}/call-MBQ_anno/execution/mobileOGs"
        File COGdir = "${workflow_dir}/call-COG_anno/execution/COG"
        File MetaCycdir = "${workflow_dir}/call-MetaCyc_anno/execution/MetaCyc"
        File kneaddatadir = "${workflow_dir}/call-kneaddata_no/execution/Result"
        # isbwa=no + binning=yes 暂不支持，bins_stats_dir 回退到 kneaddata Result
        File bins_stats_dir = "${workflow_dir}/call-kneaddata_no/execution/Result"
    }
}

task merge_upstream_results {
    File old_clean
    File new_clean
    File old_qc
    File new_qc
    File old_megahit
    File new_megahit
    File old_prodigal
    File new_prodigal
    File old_bowtie
    File new_bowtie
    File old_tax_annotation
    File new_tax_annotation
    File old_func_annotation
    File new_func_annotation

    command <<<
        set -euo pipefail
        echo "merge_upstream_results version: qc-summary-v2"
        python /root/microbiome/microbiome/metage_megahit/merge_upstream_results.py \
            --pair clean ${old_clean} ${new_clean} \
            --pair qc_result ${old_qc} ${new_qc} \
            --pair megahit ${old_megahit} ${new_megahit} \
            --pair prodigal ${old_prodigal} ${new_prodigal} \
            --pair bowtie ${old_bowtie} ${new_bowtie} \
            --pair tax_annotation ${old_tax_annotation} ${new_tax_annotation} \
            --pair func_annotation ${old_func_annotation} ${new_func_annotation} \
            --out merged
    >>>
    runtime {
        docker: "dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu: 4
        memory: "32 GB"
    }
    output {
        File clean_dir = "merged/clean"
        File qc_result = "merged/qc_result"
        File megahit = "merged/megahit"
        File prodigal = "merged/prodigal"
        File bowtie = "merged/bowtie"
        File tax_annotation = "merged/tax_annotation"
        File func_annotation = "merged/func_annotation"
    }
}

task check_input_no_raw{
    String dataDir
    String? bust_cache


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task check_input_no_raw"
        echo "cache_revision=20260806_external_project_info_v3"
        echo "bust_cache=${default='' bust_cache}"
        mkdir metadatadir
        python /root/microbiome/microbiome/metage_megahit/dealdata_update.py -indir ${dataDir} -outdir metadatadir

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I metadatadir \
            --stage check_input_no_raw \
            --key all \
            --files sample_txt=metadatadir/sample.txt sample_metadata=metadatadir/sample-metadata.tsv project_info=metadatadir/project_info.json report_no=metadatadir/report_no.txt \
            --input-samples $(awk 'NR>1 {print $2}' metadatadir/sample.txt | tr '\n' ' ')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task check_input_no_raw"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        File result ="metadatadir"
        Array[File] metadata_files = glob("metadatadir/*")
        File project_info = "metadatadir/project_info.json"
        File report_no = "metadatadir/report_no.txt"
    }
}

task check_input_with_raw{
    String dataDir
    String fastq_dir
    Boolean allow_extra_fastq = false
    Boolean allow_empty_comparison = false
    String? bust_cache


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task check_input_with_raw"
        echo "cache_revision=20260806_external_project_info_v3"
        echo "bust_cache=${default='' bust_cache}"
        mkdir metadatadir
        python /root/microbiome/microbiome/metage_megahit/dealdata_update.py \
            -indir ${dataDir} \
            -outdir metadatadir \
            ${if allow_empty_comparison then "--allow-empty-comparison" else ""}
        python /root/microbiome/microbiome/metage_megahit/check_fastq_mapping_update.py \
            ${fastq_dir} \
            metadatadir/sample.txt \
            metadatadir/sample-metadata.tsv \
            ${if allow_extra_fastq then "--allow-extra-fastq" else ""} \
            -v -o metadatadir/fastq_mapping_check_report.txt

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I metadatadir \
            --stage check_input_with_raw \
            --key all \
            --files sample_txt=metadatadir/sample.txt sample_metadata=metadatadir/sample-metadata.tsv project_info=metadatadir/project_info.json report_no=metadatadir/report_no.txt check_report=metadatadir/fastq_mapping_check_report.txt \
            --input-samples $(awk 'NR>1 {print $2}' metadatadir/sample.txt | tr '\n' ' ')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task check_input_with_raw"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        File result ="metadatadir"
        Array[File] metadata_files = glob("metadatadir/*")
        File project_info = "metadatadir/project_info.json"
        File report_no = "metadatadir/report_no.txt"
    }
}

task choose_plot_style {
    String global_font_family = ""
    String global_theme = ""
    String global_dpi = ""
    String global_width = ""
    String global_height = ""

    String title_font_family = ""
    String title_size = ""
    String title_bold = ""
    String title_italic = ""
    String title_align = ""
    String title_show = ""

    String axis_title_font_family = ""
    String axis_title_size = ""
    String axis_title_bold = ""
    String axis_title_italic = ""
    String axis_title_align = ""
    String axis_title_show = ""

    String axis_text_font_family = ""
    String axis_text_size = ""
    String axis_text_bold = ""
    String axis_text_italic = ""
    String axis_text_align = ""
    String axis_text_show = ""

    String legend_title_font_family = ""
    String legend_title_size = ""
    String legend_title_bold = ""
    String legend_title_italic = ""
    String legend_title_align = ""
    String legend_title_show = ""

    String legend_text_font_family = ""
    String legend_text_size = ""
    String legend_text_bold = ""
    String legend_text_italic = ""
    String legend_text_align = ""
    String legend_text_show = ""

    String label_font_family = ""
    String label_size = ""
    String label_bold = ""
    String label_italic = ""
    String label_align = ""
    String label_show = ""

    String legend_position = ""
    String legend_frame = ""
    String legend_show = ""
    String group_palette = ""
    File task_overrides_json

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task choose_plot_style"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39

        python /root/microbiome/microbiome/metage_megahit/choose_plot_style.py \
            --default-config /root/microbiome/microbiome/metage_megahit/plot_style.default.json \
            --task-overrides "${task_overrides_json}" \
            --out plot_style.json \
            --global-font-family "${global_font_family}" \
            --global-theme "${global_theme}" \
            --global-dpi "${global_dpi}" \
            --global-figure-width "${global_width}" \
            --global-figure-height "${global_height}" \
            --title-font-family "${title_font_family}" \
            --title-size "${title_size}" \
            --title-bold "${title_bold}" \
            --title-italic "${title_italic}" \
            --title-align "${title_align}" \
            --title-show "${title_show}" \
            --axis-title-font-family "${axis_title_font_family}" \
            --axis-title-size "${axis_title_size}" \
            --axis-title-bold "${axis_title_bold}" \
            --axis-title-italic "${axis_title_italic}" \
            --axis-title-align "${axis_title_align}" \
            --axis-title-show "${axis_title_show}" \
            --axis-text-font-family "${axis_text_font_family}" \
            --axis-text-size "${axis_text_size}" \
            --axis-text-bold "${axis_text_bold}" \
            --axis-text-italic "${axis_text_italic}" \
            --axis-text-align "${axis_text_align}" \
            --axis-text-show "${axis_text_show}" \
            --legend-title-font-family "${legend_title_font_family}" \
            --legend-title-size "${legend_title_size}" \
            --legend-title-bold "${legend_title_bold}" \
            --legend-title-italic "${legend_title_italic}" \
            --legend-title-align "${legend_title_align}" \
            --legend-title-show "${legend_title_show}" \
            --legend-text-font-family "${legend_text_font_family}" \
            --legend-text-size "${legend_text_size}" \
            --legend-text-bold "${legend_text_bold}" \
            --legend-text-italic "${legend_text_italic}" \
            --legend-text-align "${legend_text_align}" \
            --legend-text-show "${legend_text_show}" \
            --data-label-font-family "${label_font_family}" \
            --data-label-size "${label_size}" \
            --data-label-bold "${label_bold}" \
            --data-label-italic "${label_italic}" \
            --data-label-align "${label_align}" \
            --data-label-show "${label_show}" \
            --legend-position "${legend_position}" \
            --legend-frame "${legend_frame}" \
            --legend-show "${legend_show}" \
            --group-palette "${group_palette}"

        python -m json.tool plot_style.json >/dev/null
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task choose_plot_style"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"1"
        memory:"2 GB"
    }
    output {
        File plot_style = "plot_style.json"
    }
}

task prepare_registry_context {
    String project_root
    Boolean require_incremental_data = false

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task prepare_registry_context"

        REGISTRY_TSV="${project_root}/data/sample_registry.tsv"
        INCREMENTAL_DATA="${project_root}/incremental_data"

        if [ ! -s "$REGISTRY_TSV" ]; then
            echo "ERROR: reuse/incremental 模式需要已有 registry: $REGISTRY_TSV" >&2
            echo "请先成功完成一次 full 运行；流程会自动生成该文件。" >&2
            exit 2
        fi
        if [ "${require_incremental_data}" = "true" ] && [ ! -d "$INCREMENTAL_DATA" ]; then
            echo "ERROR: incremental 模式需要新增/变更样本目录: $INCREMENTAL_DATA" >&2
            exit 2
        fi

        md5sum "$REGISTRY_TSV" | awk '{print $1}' > registry_md5.txt
        echo "$REGISTRY_TSV" > registry_tsv_path.txt
        echo "$INCREMENTAL_DATA" > incremental_datapath.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task prepare_registry_context"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"1"
        memory:"2 GB"
    }
    output {
        String registry_md5 = read_string("registry_md5.txt")
        String registry_tsv = read_string("registry_tsv_path.txt")
        String incremental_datapath = read_string("incremental_datapath.txt")
    }
}

task apply_registry {
    File datapath
    String? registry_tsv
    String? registry_md5

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task apply_registry"
        echo "cache_revision=20260730_metadata_files_v2"
        # registry_md5 is referenced only to bust call-cache when registry content changes
        echo "registry_md5=${default='' registry_md5}"
        # registry copy to execution dir (v1)
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        # The current complete data.xlsx is authoritative for reuse and
        # incremental runs. The parent registry describes the previous state
        # and must not filter out newly added samples or restore deleted,
        # renamed, or regrouped samples. Copy current metadata first; the
        # successful workflow updates the persistent registry at the end.
        python /root/microbiome/microbiome/metage_megahit/apply_registry.py \
            --datadir ${datapath} \
            --outdir new_metadatadir \
            --execution-dir $(pwd)

        # Preserve display names separately, then normalize sample identifiers
        # back to stable internal IDs for all downstream file lookups.
        awk 'BEGIN {FS=OFS="\t"; print "internal_id", "display_name"}
             NR > 1 && $1 != "" {print $1, ($2 == "" ? $1 : $2)}' \
            new_metadatadir/sample.txt > new_metadatadir/display_name_map.tsv

        awk 'BEGIN {FS=OFS="\t"}
             NR == FNR {
                 if (FNR > 1 && $1 != "") name_to_id[$2] = $1
                 next
             }
             FNR == 1 || /^#/ {print; next}
             NF > 0 {
                 if ($1 in name_to_id) $1 = name_to_id[$1]
                 print
             }' \
            new_metadatadir/sample.txt \
            new_metadatadir/sample-metadata.tsv \
            > new_metadatadir/sample-metadata.tsv.tmp
        mv new_metadatadir/sample-metadata.tsv.tmp \
            new_metadatadir/sample-metadata.tsv

        awk 'BEGIN {FS=OFS="\t"}
             NR == 1 {print; next}
             $1 != "" {$2 = $1; print}' \
            new_metadatadir/sample.txt > new_metadatadir/sample.txt.tmp
        mv new_metadatadir/sample.txt.tmp new_metadatadir/sample.txt
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task apply_registry"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"4"
        memory:"8 GB"
    }
    output {
        File new_datapath ="new_metadatadir"
        Array[File] metadata_files = glob("new_metadatadir/*")
        File display_name_map ="new_metadatadir/display_name_map.tsv"
    }
}

task kneaddata_no {
    String datapath
    String rawdatapath
    String host
    String mapdir
    String checkDir
    Boolean keep_clean_reads = false
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kneaddata_no"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="qc"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        ${if keep_clean_reads then "export KEEP_CLEAN_READS=1" else "export KEEP_CLEAN_READS=0"}
        ls ${checkDir}
        python /root/microbiome/microbiome/metage_megahit/Kneaddata_update.py \
            -i ${rawdatapath} \
            -I ${datapath} \
            --host ${host} \
            --mapdir ${mapdir}/database/kneaddata_database \
            -o cleandata \
            --host_dir de_host \
            --resdir Result

        if [ ! -d de_host ]; then mkdir -p de_host; fi

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage kneaddata \
            --key all \
            --files cleandata=cleandata de_host=de_host result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kneaddata_no"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        File cleandir ="cleandata"
        File Result ="Result"
        File dohost_dir ="de_host"
    }
}

task megahit_no {
    String datapath
    String host
    File clean_dir
    File dehost_dir


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task megahit_no"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/megahit_update.py \
            -I ${datapath} \
            --cleandir ${clean_dir} \
            --host ${host} \
            --host_dir ${dehost_dir} \
            --megahit megahit

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage megahit \
            --key all \
            --files megahit=megahit \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task megahit_no"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"96"
        memory:"384 GB"
    }
    output {
        File megahit ="megahit"
    }
}

task bins {
    String datapath
    File megahit


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bins"
        bash /binscript/binning.sh ${datapath} ${megahit} binnings

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage bins \
            --key all \
            --files binnings=binnings \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bins"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metawrap:v1.79"
        cpu:"72"
        memory:"256 GB"
    }
    output {
        File binsDir ="binnings"
    }
}

task bins_drep {
    String datapath
    File binsDir


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bins_drep"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate drep
        python /root/microbiome/microbiome/metage_megahit/drep.py -I ${datapath} --binning ${binsDir}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage bins_drep \
            --key all \
            --files drep=drep \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bins_drep"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"30"
        memory:"256 GB"
    }
    output {
        File drepDir ="drep"
    }
}

task quant_classify {
    String datapath
    String host
    File drepDir
    File megahit
    File clean_dir


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task quant_classify"
        bash /binscript/quant_classify.sh ${datapath} ${clean_dir} ${drepDir} ${megahit} ${host}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage quant_classify \
            --key all \
            --files bin_classfication=bin_classfication quant_bins=quant_bins blobology=blobology \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task quant_classify"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metawrap:v1.79"
        cpu:"72"
        memory:"320 GB"
    }
    output {
        File classfiDir ="bin_classfication"
        File quantDir ="quant_bins"
        File blobologyDir ="blobology"
    }
}

task bins_stats {
    File drepDir
    File classfiDir
    File quantDir
    File blobologyDir
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bins_stats"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="bins_stats"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/bins_stats.py --blobology ${blobologyDir} --quantDir ${quantDir} --drep ${drepDir} --classfiDir ${classfiDir}
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bins_stats"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"12"
        memory:"128 GB"
    }
    output {
        File Result ="Result"
    }
}

task prodig_no {
    String datapath
    File megahit


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task prodig_no"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/prodigal_update.py \
            --megahit ${megahit} \
            --prodigal prodigal \
            --cdhitdir /app/cd-hit-v4.8.1-2019-0228 \
            --threads 60 \
            --chunk-size-mb 200

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage prodigal \
            --key all \
            --files prodigal=prodigal \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task prodig_no"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"72"
        memory:"320 GB"
    }
    output {
        File prodigal ="prodigal"
    }
}

task bwa_no {
    String datapath
    String host
    File clean_dir
    File prodigal
    File dehost_dir


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bwa_no"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/bwa_update.py \
            -I ${datapath} \
            --cleandir ${clean_dir} \
            --host ${host} \
            --prodigal ${prodigal} \
            --host_dir ${dehost_dir} \
            --bowtie bowtie

        for sample in $(awk 'NR>1 {print $2}' ${datapath}/sample.txt); do
            python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
                -I ${datapath} \
                --stage bwa \
                --key "$sample" \
                --files bam=bowtie/"$sample".sort.bam \
                --input-samples "$sample" \
                --skip-missing
        done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bwa_no"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"72"
        memory:"384 GB"
    }
    output {
        File bowtie ="bowtie"
    }
}

task tax_anno {
    String mapdir
    File prodigal
    String datapath


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_anno"
        echo "[script_revision] 20260721_tax_id_encoding_fix_v2"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery

        # 固定 diamond block-size 为 8
        BLOCK_SIZE=8
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] diamond block-size: $BLOCK_SIZE"

        python /root/microbiome/microbiome/metage_megahit/tax_ano_1_update_V2.py \
            --Annotation Annotation \
            --prodigal ${prodigal} \
            --dbdir ${mapdir}/database/NR \
            --megandir /opt/megan7/ \
            --threads 60 \
            --block-size $BLOCK_SIZE

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage tax_anno \
            --key all \
            --files annotation=Annotation \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"62"
        memory:"320 GB"
    }
    output {
        File tax_Annotation ="Annotation"
    }
}

task func_anno {
    String mapdir
    File prodigal
    String datapath


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/func_ano_1_update.py \
            --Annotation Annotation \
            --prodigal ${prodigal} \
            --dbdir ${mapdir}/database \
            --emapperdir /app/eggnog-mapper/ \
            --cpu 50 \
            --evalue 1e-5 \
            --prefix func

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage func_anno \
            --key all \
            --files annotation=Annotation \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"62"
        memory:"320 GB"
    }
    output {
        File func_Annotation ="Annotation"
    }
}

task anno {
    String mapdir
    File bowtie
    File tax_Annotation
    File func_Annotation
    String datapath


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task anno"
        echo "[script_revision] 20260721_annotation_join_fix_v2"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery

        mkdir -p Annotation

        python /root/microbiome/microbiome/metage_megahit/tax_ano_2_update.py \
            --Annotation Annotation \
            --dbdir ${mapdir}/database/NR \
            --bowtie ${bowtie} \
            --tax_anno ${tax_Annotation}

        python /root/microbiome/microbiome/metage_megahit/func_ano_2_update.py \
            --Annotation Annotation \
            --dbdir ${mapdir}/database \
            --mapdir ${mapdir} \
            --bowtie ${bowtie} \
            --fun_anno ${func_Annotation} \
            --workers 4

        python /root/microbiome/microbiome/metage_megahit/gene_func_taxonomy_update.py \
            --Annotation Annotation \
            --func_anno ${func_Annotation}/func.emapper.annotations

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage anno \
            --key all \
            --files annotation=Annotation \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        File Annotation ="Annotation"
    }
}

task VCA_anno {
    String mapdir
    File prodigal
    File bowtie
    File Annotation
    String datapath


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task VCA_anno"
        echo "[script_revision] 20260721_cycdb_detail_fix_v4"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/vfdb_update.py \
            --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database --VFDB VFDB
        python /root/microbiome/microbiome/metage_megahit/CycDB_update.py \
            --Annotation ${Annotation} --bowtie ${bowtie} --dbdir ${mapdir}/database --CycDB CycDB
        python /root/microbiome/microbiome/metage_megahit/ARGs_update.py \
            --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database --ARGdir ARGs

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage VCA_anno \
            --key all \
            --files VFDB=VFDB CycDB=CycDB ARGs=ARGs \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task VCA_anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        File VFDB ="VFDB"
        File CycDB ="CycDB"
        File ARGdir ="ARGs"
    }
}

task MBQ_anno {
    String mapdir
    File prodigal
    File bowtie
    File Annotation
    String datapath


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task MBQ_anno"
        echo "[script_revision] 20260721_annotation_join_fix_v3"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/mobileOG_update.py \
            --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database --mobileOGdir mobileOGs
        python /root/microbiome/microbiome/metage_megahit/BacMet2_update.py \
            --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database --BacMet2dir BacMet2
        python /root/microbiome/microbiome/metage_megahit/QS_update.py \
            --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database --QSdir QS

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage MBQ_anno \
            --key all \
            --files mobileOGs=mobileOGs BacMet2=BacMet2 QS=QS \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task MBQ_anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        File mobileOGs ="mobileOGs"
        File BacMet2 ="BacMet2"
        File QS ="QS"
    }
}

task tax_base {
    String datapath
    File prodigal
    File bowtie
    File Annotation
    File megahit
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_base"
        echo "[script_revision] 20260724_tax_plot_style_v8_selected_fonts_plus_2"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="tax_base"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/megahit_statistics_update.py -I ${datapath} --megahit ${megahit} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/prodigal_stats_update.py -I ${datapath} --prodigal ${prodigal} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/bwa_stats_update.py -I ${datapath} --bowtie ${bowtie} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/tax_stats_update.py -I ${datapath} --Annotation ${Annotation} --resdir Result

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage tax_base \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_base"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        File Result ="Result"
    }
}

task tax_diff {
    String datapath
    File Annotation
    File preResdir
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_diff"
        echo "[script_revision] 20260724_tax_plot_style_v8_selected_fonts_plus_2_alpha_title_18"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="tax_diff"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/tax_base_update.py -I ${datapath} --Annotation ${Annotation} --resdir Result --pre_resdir ${preResdir} -j 6
        python /root/microbiome/microbiome/metage_megahit/tax_diff_update.py -I ${datapath} --resdir Result --tpmdir tax_diff --pre_resdir ${preResdir}
        python /root/microbiome/microbiome/metage_megahit/alpha_diver_update.py ${datapath} ${preResdir} Result
        export ADDR2LINE=addr2line
        set +u
        conda activate lefse
        set -u
        python /root/microbiome/microbiome/metage_megahit/tax_lefse_update.py -I ${datapath} --res_dir Result --tpmdir tax_diff --pre_resdir ${preResdir} -t 8

        set +u
        conda activate py39
        set -u
        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage tax_diff \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_diff"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        File Result ="Result"
    }
}

task func_base {
    String datapath
    String mapdir
    File CycDB
    File ARGdir
    File Annotation
    File VFDB
    File mobileOGs
    File BacMet2
    File QS
    File COG
    File MetaCyc
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_base"
        echo "[script_revision] 20260723_function_plot_style_v4_font_plus_2"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="func_base"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_stats_update.py -I ${datapath} --Annotation ${Annotation} --dbdir ${mapdir}/database --resdir Result --func_tmp func_base
        python /root/microbiome/microbiome/metage_megahit/CycDB_stats_update.py -I ${datapath} --CycDB ${CycDB} --dbdir ${mapdir}/database --resdir Result
        python /root/microbiome/microbiome/metage_megahit/ARGs_stats_update.py -I ${datapath} --ARGdir ${ARGdir} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/vfdb_stats_update.py -I ${datapath} --vfdb_dir ${VFDB} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/mobileOG_stats_update.py -I ${datapath} --mobileOGdir ${mobileOGs} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/BacMet2_stats_update.py -I ${datapath} --BacMet2dir ${BacMet2} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/QS_stats_update.py -I ${datapath} --QSdir ${QS} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/COG_stats_update.py -I ${datapath} --COG ${COG} --resdir Result --func_tmp func_base
        python /root/microbiome/microbiome/metage_megahit/MetaCyc_stats_update.py -I ${datapath} --MetaCyc ${MetaCyc} --resdir Result --func_tmp func_base
        python /root/microbiome/microbiome/metage_megahit/gene_annotation_summary.py \
            -I ${datapath} \
            --Annotation ${Annotation} \
            --CycDB ${CycDB} \
            --ARGdir ${ARGdir} \
            --VFDB ${VFDB} \
            --mobileOGs ${mobileOGs} \
            --BacMet2 ${BacMet2} \
            --QS ${QS} \
            --COG ${COG} \
            --MetaCyc ${MetaCyc} \
            --outdir Result/GeneAnnotationSummary
        python /root/microbiome/microbiome/metage_megahit/func_base_update.py -I ${datapath} --resdir Result --func_tmp func_base

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage func_base \
            --key all \
            --files result=Result func_base=func_base \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_base"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        File Result ="Result"
        File funcBase ="func_base"
    }
}

task func_diff {
    String datapath
    File funcBase
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_diff"
        echo "[script_revision] 20260723_function_diff_plot_style_v3_font_plus_2"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="func_diff"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_diff_update_cog_metacyc.py -I ${datapath} --resdir Result --func_tmp ${funcBase} --func_diff func_diff
        export ADDR2LINE=addr2line
        set +u
        conda activate lefse
        set -u
        python /root/microbiome/microbiome/metage_megahit/func_lefse_update.py -I ${datapath} --resdir Result --func_tmp ${funcBase} --func_diff func_diff -t 8

        set +u
        conda activate py39
        set -u
        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage func_diff \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_diff"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        File Result ="Result"
    }
}

task coll_res_ana {
    String datapath
    String analyse
    String binning
    File Res1
    File Res2
    File Res3
    File Res4
    File Res5
    File? display_name_map
    String host
    File? qc_cleandir
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_ana"
        echo "[script_revision] 20260723_report_plot_style_v3_font_plus_2"
        echo "QC replot with final registry metadata"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="qc"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_update.py \
            --res1 ${Res1} --res2 ${Res2} --res3 ${Res3} --res4 ${Res4} --res5 ${Res5} \
            --readme /root/microbiome/microbiome/metage_megahit \
            --outdir Result_update
        QC_CLEANDIR="${default="" qc_cleandir}"
        if [ -n "$QC_CLEANDIR" ]; then
            python /root/microbiome/microbiome/metage_megahit/replot_qc_update.py \
                --table-dir "$QC_CLEANDIR/table" --data-dir ${datapath} \
                --result-dir Result_update/Result --host ${host}
        else
            echo "[WARN] QC table directory unavailable; skipping QC figure regeneration" >&2
        fi
        python /root/microbiome/microbiome/metage_megahit/pdf2png_update.py -resDir Result_update --dpi 300 -j 8
        python /root/microbiome/microbiome/metage_megahit/get_report_update.py \
            -I ${datapath} --analyse ${analyse} --binning ${binning} --res_dir Result_update --image-mode full \
            ${if defined(display_name_map) then "--display-name-map " + display_name_map else ""}
        python /root/microbiome/microbiome/metage_megahit/get_groups_update.py -I ${datapath} --res Result_update
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans_update.py --res Result_update --font 宋体 -j 8

        MAP_ARG="${if defined(display_name_map) then "--map " + display_name_map else ""}"
        QC_ARG=""
        if [ -n "$QC_CLEANDIR" ]; then
            QC_ARG="--qc-table-dir $QC_CLEANDIR/table --qc-data-dir ${datapath} --host ${host}"
        fi
        if [ -n "$MAP_ARG" ]; then
            python /root/microbiome/microbiome/metage_megahit/rewrite_display_names.py --res_dir Result_update $MAP_ARG $QC_ARG
        fi

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage coll_res_ana \
            --key all \
            --files result=Result_update \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task coll_res_ana"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        File Result ="Result_update"
    }
}

task coll_res_ana_bins {
    String datapath
    String analyse
    String binning
    File Res1
    File Res2
    File Res3
    File Res4
    File Res5
    File Res6
    File? display_name_map
    String host
    File? qc_cleandir
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_ana_bins"
        echo "[script_revision] 20260723_report_plot_style_v3_font_plus_2"
        echo "QC replot with final registry metadata"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="qc"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_bins_update.py \
            --res1 ${Res1} --res2 ${Res2} --res3 ${Res3} --res4 ${Res4} --res5 ${Res5} --res6 ${Res6} \
            --readme /root/microbiome/microbiome/metage_megahit \
            --outdir Result_update
        QC_CLEANDIR="${default="" qc_cleandir}"
        if [ -n "$QC_CLEANDIR" ]; then
            python /root/microbiome/microbiome/metage_megahit/replot_qc_update.py \
                --table-dir "$QC_CLEANDIR/table" --data-dir ${datapath} \
                --result-dir Result_update/Result --host ${host}
        else
            echo "[WARN] QC table directory unavailable; skipping QC figure regeneration" >&2
        fi
        python /root/microbiome/microbiome/metage_megahit/pdf2png_update.py -resDir Result_update --dpi 300 -j 8
        python /root/microbiome/microbiome/metage_megahit/get_report_update.py \
            -I ${datapath} --analyse ${analyse} --binning ${binning} --res_dir Result_update --image-mode full \
            ${if defined(display_name_map) then "--display-name-map " + display_name_map else ""}
        python /root/microbiome/microbiome/metage_megahit/get_groups_update.py -I ${datapath} --res Result_update
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans_update.py --res Result_update --font 宋体 -j 8

        MAP_ARG="${if defined(display_name_map) then "--map " + display_name_map else ""}"
        QC_ARG=""
        if [ -n "$QC_CLEANDIR" ]; then
            QC_ARG="--qc-table-dir $QC_CLEANDIR/table --qc-data-dir ${datapath} --host ${host}"
        fi
        if [ -n "$MAP_ARG" ]; then
            python /root/microbiome/microbiome/metage_megahit/rewrite_display_names.py --res_dir Result_update $MAP_ARG $QC_ARG
        fi

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage coll_res_ana_bins \
            --key all \
            --files result=Result_update \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task coll_res_ana_bins"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        File Result ="Result_update"
    }
}

task coll_res_NOana {
    String datapath
    String analyse
    String binning
    File Res1
    File Res2
    File Res3
    File? display_name_map
    String host
    File? qc_cleandir
    File plot_style


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_NOana"
        echo "[script_revision] 20260723_report_plot_style_v3_font_plus_2"
        echo "QC replot with final registry metadata"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="qc"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_NOana_update.py \
            --res1 ${Res1} --res2 ${Res2} --res3 ${Res3} \
            --readme /root/microbiome/microbiome/metage_megahit \
            --outdir Result_update
        QC_CLEANDIR="${default="" qc_cleandir}"
        if [ -n "$QC_CLEANDIR" ]; then
            python /root/microbiome/microbiome/metage_megahit/replot_qc_update.py \
                --table-dir "$QC_CLEANDIR/table" --data-dir ${datapath} \
                --result-dir Result_update/Result --host ${host}
        else
            echo "[WARN] QC table directory unavailable; skipping QC figure regeneration" >&2
        fi
        python /root/microbiome/microbiome/metage_megahit/pdf2png_update.py -resDir Result_update --dpi 300 -j 8
        python /root/microbiome/microbiome/metage_megahit/get_report_update.py \
            -I ${datapath} --analyse ${analyse} --binning ${binning} --res_dir Result_update --image-mode full \
            ${if defined(display_name_map) then "--display-name-map " + display_name_map else ""}
        python /root/microbiome/microbiome/metage_megahit/get_groups_update.py -I ${datapath} --res Result_update
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans_update.py --res Result_update --font 宋体 -j 8

        MAP_ARG="${if defined(display_name_map) then "--map " + display_name_map else ""}"
        QC_ARG=""
        if [ -n "$QC_CLEANDIR" ]; then
            QC_ARG="--qc-table-dir $QC_CLEANDIR/table --qc-data-dir ${datapath} --host ${host}"
        fi
        if [ -n "$MAP_ARG" ]; then
            python /root/microbiome/microbiome/metage_megahit/rewrite_display_names.py --res_dir Result_update $MAP_ARG $QC_ARG
        fi

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage coll_res_NOana \
            --key all \
            --files result=Result_update \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task coll_res_NOana"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        File Result ="Result_update"
    }
}

task res2json {
    String datapath
    File res_dir


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task res2json"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/res2json_update.py \
            --sorc_path ${res_dir} -I ${datapath} --dest_path jsonFile --max-files 20

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage res2json \
            --key all \
            --files jsonFile=jsonFile \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task res2json"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        File jsonFile="jsonFile"
    }
}

task resFile {
    File report_no
    File res_dir
    File projectinfo


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task resFile"
        bash /root/microbiome/microbiome/metage_megahit/result_manger_update.sh ${res_dir} Result
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task resFile"
    >>>

    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        File respath = "Result"
        File PDFpath = "Result/report.pdf"
        File docxpath = "Result/report.docx"
        File reportNOdir = "${report_no}"
        File project_info = "${projectinfo}"
    }
}


task kraken2_anno {
    File cleandir
    String datapath
    String kraken2_db
    Int threads = 16

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate kraken2
        python /root/microbiome/microbiome/metage_megahit/kraken2_anno_update.py \
            -i ${cleandir} \
            -I ${datapath} \
            --db ${kraken2_db} \
            -o kraken2_out \
            --threads ${threads}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage kraken2_anno \
            --key all \
            --files kraken2_out=kraken2_out \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kraken2_anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"${threads}"
        memory:"128 GB"
    }
    output {
        File kraken2_out = "kraken2_out"
    }
}

task kraken2_tax_base {
    String datapath
    File kraken2_out
    File plot_style

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_tax_base"
        echo "[script_revision] 20260723_tax_plot_style_v5_font_plus_2"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="kraken2_tax_base"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/kraken2_stats_update.py \
            -I ${datapath} \
            --kraken2_out ${kraken2_out} \
            --resdir Result

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage kraken2_tax_base \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kraken2_tax_base"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        File Result = "Result"
    }
}

task kraken2_tax_diff {
    String datapath
    File preResdir
    Int threads = 8
    File plot_style

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_tax_diff"
        echo "[script_revision] 20260724_tax_plot_style_v8_selected_fonts_plus_2_alpha_title_18"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="kraken2_tax_diff"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/tax_base_update.py \
            -I ${datapath} \
            --Annotation ${preResdir}/kraken2_taxonomy \
            --resdir Result \
            --pre_resdir ${preResdir} \
            -j 6
        python /root/microbiome/microbiome/metage_megahit/tax_diff_update.py \
            -I ${datapath} \
            --resdir Result \
            --tpmdir tax_diff \
            --pre_resdir ${preResdir}
        python /root/microbiome/microbiome/metage_megahit/alpha_diver_update.py \
            ${datapath} ${preResdir} Result
        set +u
        conda activate lefse
        set -u
        python /root/microbiome/microbiome/metage_megahit/tax_lefse_update.py \
            -I ${datapath} \
            --res_dir Result \
            --tpmdir tax_diff \
            --pre_resdir ${preResdir} \
            -t ${threads}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage kraken2_tax_diff \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kraken2_tax_diff"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"${threads}"
        memory:"64 GB"
    }
    output {
        File Result = "Result"
    }
}

task COG_anno {
    String mapdir
    File prodigal
    File bowtie
    File Annotation
    String datapath

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task COG_anno"
        echo "[script_revision] 20260721_annotation_join_fix_v3"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/COG_update.py \
            --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database --COGdir COG

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage COG_anno \
            --key all \
            --files COG=COG \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task COG_anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        File COG = "COG"
    }
}

task MetaCyc_anno {
    String mapdir
    File prodigal
    File bowtie
    File Annotation
    String datapath

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task MetaCyc_anno"
        echo "[script_revision] 20260721_annotation_join_fix_v3"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/MetaCyc_update.py \
            --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database --MetaCycdir MetaCyc

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ${datapath} \
            --stage MetaCyc_anno \
            --key all \
            --files MetaCyc=MetaCyc \
            --input-samples $(awk 'NR>1 {print $2}' ${datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task MetaCyc_anno"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        File MetaCyc = "MetaCyc"
    }
}

task ref_assembly {
    String datapath
    File cleandir
    String ref_sample

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task ref_assembly"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/ref_assembly_update.py \
            -I ${datapath} \
            --cleandir ${cleandir} \
            --ref_sample ${ref_sample} \
            -o ref_assembly \
            --threads 24
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task ref_assembly"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        File ref_assembly_dir = "ref_assembly"
        File ref_fasta = "ref_assembly/ref.fa"
    }
}

task ref_mapping {
    String datapath
    File cleandir
    File ref_fasta

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task ref_mapping"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/ref_mapping_update.py \
            -I ${datapath} \
            --cleandir ${cleandir} \
            --ref_fasta ${ref_fasta} \
            -o ref_mapping \
            --threads 16
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task ref_mapping"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"32"
        memory:"256 GB"
    }
    output {
        File ref_mapping_dir = "ref_mapping"
    }
}

task snp_calling {
    String datapath
    File bamdir
    File ref_fasta
    File plot_style

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task snp_calling"
        echo "[script_revision] 20260723_snp_plot_style_v2_font_plus_2"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="snp_calling"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/snp_calling_update.py \
            -I ${datapath} \
            --bamdir ${bamdir} \
            --ref_fasta ${ref_fasta} \
            -o snp_calling \
            --threads 8
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task snp_calling"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"16"
        memory:"128 GB"
    }
    output {
        File snp_dir = "snp_calling"
    }
}

task tax_unifrac {
    String datapath
    String tax_tree
    File resdir
    File plot_style

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_unifrac"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="tax_unifrac"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/tax_unifrac_update.py \
            -I ${datapath} \
            --tree ${tax_tree} \
            --resdir ${resdir} \
            --outdir tax_unifrac
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_unifrac"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"12"
        memory:"128 GB"
    }
    output {
        File tax_unifrac_out = "tax_unifrac"
    }
}

task func_unifrac {
    String datapath
    String func_tree
    File funcBase
    File plot_style

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_unifrac"
        export METAGE_PLOT_CONFIG="${plot_style}"
        export METAGE_PLOT_TASK="func_unifrac"
        export R_PROFILE_USER=/root/microbiome/microbiome/metage_megahit/plot_theme_profile.R
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_unifrac_update.py \
            -I ${datapath} \
            --tree ${func_tree} \
            --func_tmp ${funcBase} \
            --outdir func_unifrac
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_unifrac"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"12"
        memory:"128 GB"
    }
    output {
        File func_unifrac_out = "func_unifrac"
    }
}


task update_registry {
    String registry_tsv_path
    File project_info
    File workflow_success_marker

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task update_registry"
        test -s "${workflow_success_marker}"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39

        # 当前 task 工作目录形如 .../<uuid>/call-update_registry/execution/
        # 向上两级即为当前 workflow 执行根目录，避免扫描所有历史 workflow 导致 registry 膨胀
        WORKFLOW_DIR=$(dirname $(dirname $(pwd)))

        # registry 固定命名为 sample_registry.tsv，项目编号从本次输入元数据读取。
        FILTER_PROJECT_NO=$(python -c 'import json,sys; print(str(json.load(open(sys.argv[1], encoding="utf-8")).get("项目编号", "")).strip())' "${project_info}")
        if [ -z "$FILTER_PROJECT_NO" ]; then
            echo "ERROR: project_info.json 中缺少 项目编号" >&2
            exit 2
        fi

        python /root/microbiome/microbiome/metage_megahit/update_registry_from_wdl.py \
            --registry ${registry_tsv_path} \
            --execution-dir "$WORKFLOW_DIR" \
            --filter-project-no "$FILTER_PROJECT_NO" \
            --drop-missing \
            --out ${registry_tsv_path} \
            --copy-to $(pwd)

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task update_registry"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:670998ebcbdbf598dc1e01f9b01dc68b5df2c465bb25532281397e89b47a3737"
        cpu:"2"
        memory:"4 GB"
    }
    output {
        String updated_registry_tsv_path = "${registry_tsv_path}"
    }
}
