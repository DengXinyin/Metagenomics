# Legacy draft-2 platform compatibility build.
# Generated from the development-syntax incremental WDL; do not edit by hand.


workflow metage_megahit2_update {
    String datapath="/home/xydeng/Metagenomics_Docker/Input/data"
    String rawdatapath="/home/xydeng/Metagenomics_Docker/Input/rawdata"
    String host="none"
    String mapdir="/cephfs_data/genostack_v3/genostack_php/public_file_data/metagenome-DB"
    String binning='no'
    String analyse='yes'
    String report_no='/home/xydeng/Metagenomics_Docker/Input/report_no.txt'
    String project="/home/xydeng/Metagenomics_Docker/Input/project_info.json"
    String isbwa="yes"
    String Taskid=""
    String project_root="/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy_test_20260724"

    # full: 全部样本跑上游；incremental: 仅新增/变更样本跑上游后合并；reuse: 直接复用上游
    String run_mode="full"
    # 首次 full 运行不需要父流程；仅 reuse/incremental 时才需要提供。
    String? parent_workflow_dir
    String? incremental_datapath

    # sample registry for incremental rename/group change
    # 平台直接填写可访问的 registry 绝对路径；不使用 File?，避免前端将其锁定为不可编辑上传项。
    String? sample_registry_tsv

    # registry content md5 to bust apply_registry call-cache when display_name changes
    String? registry_md5

    # registry auto-update parameters
    String? registry_tsv_path
    String? executions_root
    Array[String]? skip_workflows

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

    if (run_mode == "full" || run_mode == "incremental"){
        call check_input_with_raw {
            input:
                dataDir=if run_mode == "incremental" then select_first([incremental_datapath]) else datapath,
                fastq_dir=rawdatapath,
                project_info=project,
                allow_extra_fastq=run_mode == "incremental",
                allow_empty_comparison=run_mode == "incremental",
                bust_cache=registry_md5
        }
        call kneaddata_no {
            input:
                datapath=check_input_with_raw.result,
                rawdatapath=rawdatapath,
                host=host,
                mapdir=mapdir,
                checkDir=check_input_with_raw.result,
                keep_clean_reads=use_kraken2
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
                    kraken2_out=kraken2_anno.kraken2_out
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
                    ref_fasta=ref_assembly.ref_fasta
            }
        }
    }

    if(run_mode != "full"){
        call check_input_no_raw {
            input:
                dataDir=datapath,
                project_info=project,
                bust_cache=registry_md5
        }
        call deal_parameter {
            input:
                workflow_dir=select_first([parent_workflow_dir])
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
            registry_tsv=sample_registry_tsv,
            registry_md5=registry_md5
    }

    call tax_base {
        input:
            megahit=select_first([merge_upstream_results.megahit, megahit_no.megahit,deal_parameter.megahitdir]),
            datapath=apply_registry.new_datapath,
            prodigal=select_first([merge_upstream_results.prodigal, prodig_no.prodigal, deal_parameter.prodigdir]),
            bowtie=select_first([merge_upstream_results.bowtie, bwa_no.bowtie, deal_parameter.bwadir]),
            Annotation=select_first([anno.Annotation, deal_parameter.anno_dir])
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
            MetaCyc=select_first([MetaCyc_anno.MetaCyc, deal_parameter.MetaCycdir])
    }

    if (analyse == 'yes'){
        call tax_diff {
            input:
                datapath=apply_registry.new_datapath,
                preResdir=tax_base.Result,
                Annotation=select_first([anno.Annotation, deal_parameter.anno_dir])
        }
        if (use_kraken2 && defined(kraken2_db) && run_mode == "full") {
            call kraken2_tax_diff {
                input:
                    datapath=apply_registry.new_datapath,
                    preResdir=select_first([kraken2_tax_base.Result])
            }
        }
        call func_diff {
            input:
                datapath=apply_registry.new_datapath,
                funcBase=func_base.funcBase
        }

        if (do_unifrac && defined(tax_tree)) {
            call tax_unifrac {
                input:
                    datapath=apply_registry.new_datapath,
                    tax_tree=select_first([tax_tree]),
                    resdir=tax_diff.Result
            }
        }
        if (do_unifrac && defined(func_tree)) {
            call func_unifrac {
                input:
                    datapath=apply_registry.new_datapath,
                    func_tree=select_first([func_tree]),
                    funcBase=func_base.funcBase
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
                    qc_cleandir=select_first([merge_upstream_results.clean_dir, kneaddata_no.cleandir, deal_parameter.clean_dir])
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
                    qc_cleandir=select_first([merge_upstream_results.clean_dir, kneaddata_no.cleandir, deal_parameter.clean_dir])
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
                qc_cleandir=select_first([merge_upstream_results.clean_dir, kneaddata_no.cleandir, deal_parameter.clean_dir])
        }
    }

    call res2json {
        input:
            res_dir=select_first([coll_res_ana.Result, coll_res_NOana.Result, coll_res_ana_bins.Result]),
            datapath=apply_registry.new_datapath
    }

    call resFile {
        input:
            report_no=report_no,
            projectinfo = project,
            res_dir=select_first([coll_res_ana.Result, coll_res_NOana.Result, coll_res_ana_bins.Result])
    }

    # 自动更新文件级 sample_registry.tsv
    if (defined(registry_tsv_path) && defined(executions_root)) {
        call update_registry {
            input:
                registry_tsv_path=select_first([registry_tsv_path]),
                executions_root=select_first([executions_root]),
                skip_workflows=select_first([skip_workflows, []]),
                workflow_success_marker=resFile.PDFpath
        }
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
        echo "Passing parameters"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task deal_parameter"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker: "dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
    String project_info
    String? bust_cache


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task check_input_no_raw"
        echo "bust_cache=${default='' bust_cache}"
        mkdir metadatadir
        cp ${project_info} metadatadir/
        python /root/microbiome/microbiome/metage_megahit/dealdata_update.py -indir ${dataDir} -outdir metadatadir

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I metadatadir \
            --stage check_input_no_raw \
            --key all \
            --files sample_txt=metadatadir/sample.txt sample_metadata=metadatadir/sample-metadata.tsv project_info=metadatadir/project_info.json \
            --input-samples $(awk 'NR>1 {print $2}' metadatadir/sample.txt | tr '\n' ' ')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task check_input_no_raw"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        File result ="metadatadir"
    }
}

task check_input_with_raw{
    String dataDir
    String fastq_dir
    String project_info
    Boolean allow_extra_fastq = false
    Boolean allow_empty_comparison = false
    String? bust_cache


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task check_input_with_raw"
        echo "bust_cache=${default='' bust_cache}"
        mkdir metadatadir
        cp ${project_info} metadatadir/
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
            --files sample_txt=metadatadir/sample.txt sample_metadata=metadatadir/sample-metadata.tsv project_info=metadatadir/project_info.json check_report=metadatadir/fastq_mapping_check_report.txt \
            --input-samples $(awk 'NR>1 {print $2}' metadatadir/sample.txt | tr '\n' ' ')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task check_input_with_raw"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        File result ="metadatadir"
    }
}

task apply_registry {
    File datapath
    String? registry_tsv
    String? registry_md5

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task apply_registry"
        # registry_md5 is referenced only to bust call-cache when registry content changes
        echo "registry_md5=${default='' registry_md5}"
        # registry copy to execution dir (v1)
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        if [ -n "${default='' registry_tsv}" ]; then
            python /root/microbiome/microbiome/metage_megahit/apply_registry.py \
                --datadir ${datapath} \
                --registry ${registry_tsv} \
                --outdir new_metadatadir \
                --execution-dir $(pwd) \
                --copy-to-execution
        else
            python /root/microbiome/microbiome/metage_megahit/apply_registry.py \
                --datadir ${datapath} \
                --outdir new_metadatadir \
                --execution-dir $(pwd) \
                --copy-to-execution
        fi
        # 无 registry 时旧版 apply_registry.py 只复制元数据，不会生成该文件。
        # 补充 identity map，保证声明的输出存在，且平台无需依赖本地脚本挂载。
        if [ ! -s new_metadatadir/display_name_map.tsv ]; then
            awk 'BEGIN {FS=OFS="\t"; print "internal_id", "display_name"}
                 NR > 1 && $1 != "" {print $1, ($2 == "" ? $1 : $2)}' \
                new_metadatadir/sample.txt > new_metadatadir/display_name_map.tsv
        fi
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task apply_registry"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
        cpu:"4"
        memory:"8 GB"
    }
    output {
        File new_datapath ="new_metadatadir"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kneaddata_no"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bins_stats"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/bins_stats.py --blobology ${blobologyDir} --quantDir ${quantDir} --drep ${drepDir} --classfiDir ${classfiDir}
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bins_stats"
    >>>
    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_base"
        echo "[script_revision] 20260724_tax_plot_style_v8_selected_fonts_plus_2"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_diff"
        echo "[script_revision] 20260724_tax_plot_style_v8_selected_fonts_plus_2_alpha_title_18"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_base"
        echo "[script_revision] 20260723_function_plot_style_v4_font_plus_2"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_diff"
        echo "[script_revision] 20260723_function_diff_plot_style_v3_font_plus_2"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_ana"
        echo "[script_revision] 20260723_report_plot_style_v3_font_plus_2"
        echo "QC replot with final registry metadata"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_ana_bins"
        echo "[script_revision] 20260723_report_plot_style_v3_font_plus_2"
        echo "QC replot with final registry metadata"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_NOana"
        echo "[script_revision] 20260723_report_plot_style_v3_font_plus_2"
        echo "QC replot with final registry metadata"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
    String projectinfo


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task resFile"
        bash /root/microbiome/microbiome/metage_megahit/result_manger_update.sh ${res_dir} Result
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task resFile"
    >>>

    runtime {
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_tax_base"
        echo "[script_revision] 20260723_tax_plot_style_v5_font_plus_2"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_tax_diff"
        echo "[script_revision] 20260724_tax_plot_style_v8_selected_fonts_plus_2_alpha_title_18"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task snp_calling"
        echo "[script_revision] 20260723_snp_plot_style_v2_font_plus_2"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_unifrac"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
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

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_unifrac"
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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
        cpu:"12"
        memory:"128 GB"
    }
    output {
        File func_unifrac_out = "func_unifrac"
    }
}


task update_registry {
    String registry_tsv_path
    String executions_root
    Array[String] skip_workflows = []
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

        # 从 registry 文件名推断目标项目编号（文件名格式：{项目编号}_xxx_sample_registry.tsv）
        REGISTRY_BASENAME=$(basename "${registry_tsv_path}")
        FILTER_PROJECT_NO=$(echo "$REGISTRY_BASENAME" | cut -d'_' -f1)

        # 构建 skip 参数（保留以兼容未来需要跳过测试 workflow 的场景）
        SKIP_ARGS=""
        for wf in ${sep=' ' skip_workflows}; do
            SKIP_ARGS="$SKIP_ARGS --skip-workflow $wf"
        done

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
        docker:"dockerhub.genostack.com/sanshu/metage_megahit@sha256:387692a4960b0048ccdf3ef4ff4a57cbb55b0feb4b4324cc9ed91937c8bf7384"
        cpu:"2"
        memory:"4 GB"
    }
    output {
        String updated_registry_tsv_path = "${registry_tsv_path}"
    }
}
