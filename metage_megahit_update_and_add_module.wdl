version development

workflow metage_megahit2_update {
    input {
        String datapath="/home/xydeng/Metagenomics_Docker/Input/data"
        String rawdatapath="/home/xydeng/Metagenomics_Docker/Input/rawdata"
        String host="none"
        String mapdir="/data/data2/metagenome-DB"
        String binning='no'
        String analyse='yes'
        String report_no='/home/xydeng/Metagenomics_Docker/Input/report_no.txt'
        String project="/home/xydeng/Metagenomics_Docker/Input/project_info.json"
        String isbwa="yes"
        String Taskid="test-run-optimized-001"

        # kraken2 optional species annotation
        Boolean use_kraken2 = false
        Directory? kraken2_db

        # reference genome assembly / mapping / SNP calling
        String ref_sample = ""

        # UniFrac beta diversity
        Boolean do_unifrac = false
        File? tax_tree
        File? func_tree
    }

    if (isbwa == "yes"){
        call check_input_with_raw {
            input:
                dataDir=datapath,
                fastq_dir=rawdatapath,
                project_info=project
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
        call anno {
            input:
                bowtie=bwa_no.bowtie,
                tax_Annotation=tax_anno.tax_Annotation,
                func_Annotation=func_anno.func_Annotation,
                mapdir=mapdir,
                datapath=check_input_with_raw.result
        }
        call VCA_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=prodig_no.prodigal,
                bowtie=bwa_no.bowtie,
                mapdir=mapdir,
                datapath=check_input_with_raw.result
        }
        call MBQ_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=prodig_no.prodigal,
                bowtie=bwa_no.bowtie,
                mapdir=mapdir,
                datapath=check_input_with_raw.result
        }

        call COG_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=prodig_no.prodigal,
                bowtie=bwa_no.bowtie,
                mapdir=mapdir,
                datapath=check_input_with_raw.result
        }

        call MetaCyc_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=prodig_no.prodigal,
                bowtie=bwa_no.bowtie,
                mapdir=mapdir,
                datapath=check_input_with_raw.result
        }

        if (ref_sample != "") {
            call ref_assembly {
                input:
                    datapath=check_input_with_raw.result,
                    cleandir=kneaddata_no.cleandir,
                    ref_sample=ref_sample
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

    if(isbwa == "no"){
        call check_input_no_raw {
            input:
                dataDir=datapath,
                project_info=project
        }
        call deal_parameter {
            input:
                taskid=Taskid
        }
    }

    call tax_base {
        input:
            megahit=select_first([megahit_no.megahit,deal_parameter.megahitdir]),
            datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
            prodigal=select_first([prodig_no.prodigal, deal_parameter.prodigdir]),
            bowtie=select_first([bwa_no.bowtie, deal_parameter.bwadir]),
            Annotation=select_first([anno.Annotation, deal_parameter.anno_dir])
    }

    call func_base {
        input:
            datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
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
                datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                preResdir=tax_base.Result,
                Annotation=select_first([anno.Annotation, deal_parameter.anno_dir])
        }
        if (use_kraken2 && defined(kraken2_db)) {
            call kraken2_tax_diff {
                input:
                    datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                    preResdir=select_first([kraken2_tax_base.Result])
            }
        }
        call func_diff {
            input:
                datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                funcBase=func_base.funcBase
        }

        if (do_unifrac && defined(tax_tree)) {
            call tax_unifrac {
                input:
                    datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                    tax_tree=select_first([tax_tree]),
                    resdir=tax_diff.Result
            }
        }
        if (do_unifrac && defined(func_tree)) {
            call func_unifrac {
                input:
                    datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                    func_tree=select_first([func_tree]),
                    funcBase=func_base.funcBase
            }
        }
        if (binning == 'yes'){
            call coll_res_ana_bins {
                input:
                    datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                    analyse=analyse,
                    binning=binning,
                    Res1=select_first([kneaddata_no.Result,deal_parameter.kneaddatadir]),
                    Res2=tax_base.Result,
                    Res3=func_base.Result,
                    Res4=tax_diff.Result,
                    Res5=func_diff.Result,
                    Res6=select_first([bins_stats.Result,deal_parameter.bingdir])
            }
        }
        if (binning == 'no'){
            call coll_res_ana {
                input:
                    datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                    analyse=analyse,
                    binning=binning,
                    Res1=select_first([kneaddata_no.Result,deal_parameter.kneaddatadir]),
                    Res2=tax_base.Result,
                    Res3=func_base.Result,
                    Res4=tax_diff.Result,
                    Res5=func_diff.Result
            }
        }
    }

    if (analyse == 'no') {
        call coll_res_NOana {
            input:
                datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                analyse=analyse,
                binning=binning,
                Res1=select_first([kneaddata_no.Result,deal_parameter.kneaddatadir]),
                Res2=tax_base.Result,
                Res3=func_base.Result
        }
    }

    call res2json {
        input:
            res_dir=select_first([coll_res_ana.Result, coll_res_NOana.Result, coll_res_ana_bins.Result]),
            datapath=select_first([check_input_with_raw.result, check_input_no_raw.result])
    }

    call resFile {
        input:
            report_no=report_no,
            projectinfo = project,
            res_dir=select_first([coll_res_ana.Result, coll_res_NOana.Result, coll_res_ana_bins.Result])
    }

    output {
        Directory respath = resFile.respath
        File pdfFile = resFile.PDFpath
        File docxpath = resFile.docxpath
        File jsonpath = res2json.jsonFile
        File reportNo = resFile.reportNOdir
        File infoFile = resFile.project_info
        Directory? kraken2_out = kraken2_anno.kraken2_out
        Directory? kraken2_tax_base_result = kraken2_tax_base.Result
        Directory? kraken2_tax_diff_result = kraken2_tax_diff.Result
        Directory? ref_assembly_dir = ref_assembly.ref_assembly_dir
        Directory? ref_mapping_dir = ref_mapping.ref_mapping_dir
        Directory? snp_dir = snp_calling.snp_dir
        Directory? tax_unifrac_out = tax_unifrac.tax_unifrac_out
        Directory? func_unifrac_out = func_unifrac.func_unifrac_out
    }
}
task deal_parameter{
    input {
        String taskid
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task deal_parameter"
        echo "Passing parameters"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task deal_parameter"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        Directory clean_dir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-kneaddata/execution/cleandata"
        Directory megahitdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-megahit_no/execution/megahit"
        Directory prodigdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-prodig_no/execution/prodigal"
        Directory bingdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-kneaddata/execution/cleandata"
        Directory bwadir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-bwa_no/execution/bowtie"
        Directory func_annodir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-func_anno/execution/Annotation"
        Directory anno_dir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-anno/execution/Annotation"
        Directory tax_annodir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-tax_anno/execution/Annotation"
        Directory ARGsdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-VCA_anno/execution/ARGs"
        Directory CycDBdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-VCA_anno/execution/CycDB"
        Directory VFDBdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-VCA_anno/execution/VFDB"
        Directory BacMet2_annodir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-MBQ_anno/execution/BacMet2"
        Directory QS_annodir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-MBQ_anno/execution/QS"
        Directory mobileOG_annodir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-MBQ_anno/execution/mobileOGs"
        Directory COGdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-COG_anno/execution/COG"
        Directory MetaCycdir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-MetaCyc_anno/execution/MetaCyc"
        Directory kneaddatadir = "/home/xydeng/Metagenomics_Docker/metage_v2.87_dxy/cromwell-executions/metage_megahit2/~{taskid}/call-kneaddata_no/execution/Result"
    }
}

task check_input_no_raw{
    input {
        String dataDir
        String project_info
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task check_input_no_raw"
        mkdir metadatadir
        cp ~{project_info} metadatadir/
        python /root/microbiome/microbiome/metage_megahit/dealdata_update.py -indir ~{dataDir} -outdir metadatadir

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I metadatadir \
            --stage check_input_no_raw \
            --key all \
            --files sample_txt=metadatadir/sample.txt sample_metadata=metadatadir/sample-metadata.tsv project_info=metadatadir/project_info.json \
            --input-samples $(awk 'NR>1 {print $2}' metadatadir/sample.txt | tr '\n' ' ')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task check_input_no_raw"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        Directory result ="metadatadir"
    }
}

task check_input_with_raw{
    input {
        String dataDir
        String fastq_dir
        String project_info
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task check_input_with_raw"
        mkdir metadatadir
        cp ~{project_info} metadatadir/
        python /root/microbiome/microbiome/metage_megahit/dealdata_update.py -indir ~{dataDir} -outdir metadatadir
        python /root/microbiome/microbiome/metage_megahit/check_fastq_mapping_update.py \
            ~{fastq_dir} \
            metadatadir/sample.txt \
            metadatadir/sample-metadata.tsv \
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
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"20 GB"
    }
    output {
        Directory result ="metadatadir"
    }
}

task kneaddata_no {
    input {
        String datapath
        String rawdatapath
        String host
        String mapdir
        String checkDir
        Boolean keep_clean_reads = false
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kneaddata_no"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        ~{if keep_clean_reads then "export KEEP_CLEAN_READS=1" else "export KEEP_CLEAN_READS=0"}
        ls ~{checkDir}
        python /root/microbiome/microbiome/metage_megahit/Kneaddata_update.py \
            -i ~{rawdatapath} \
            -I ~{datapath} \
            --host ~{host} \
            --mapdir ~{mapdir}/database/kneaddata_database \
            -o cleandata \
            --host_dir de_host \
            --resdir Result

        if [ ! -d de_host ]; then mkdir -p de_host; fi

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage kneaddata \
            --key all \
            --files cleandata=cleandata de_host=de_host result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kneaddata_no"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        Directory cleandir ="cleandata"
        Directory Result ="Result"
        Directory dohost_dir ="de_host"
    }
}

task megahit_no {
    input {
        String datapath
        String host
        Directory clean_dir
        Directory dehost_dir
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task megahit_no"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/megahit_update.py \
            -I ~{datapath} \
            --cleandir ~{clean_dir} \
            --host ~{host} \
            --host_dir ~{dehost_dir} \
            --megahit megahit

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage megahit \
            --key all \
            --files megahit=megahit \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task megahit_no"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"96"
        memory:"720 GB"
    }
    output {
        Directory megahit ="megahit"
    }
}

task bins {
    input {
        String datapath
        Directory megahit
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bins"
        bash /binscript/binning.sh ~{datapath} ~{megahit} binnings

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage bins \
            --key all \
            --files binnings=binnings \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bins"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metawrap:v1.79"
        cpu:"72"
        memory:"256 GB"
    }
    output {
        Directory binsDir ="binnings"
    }
}

task bins_drep {
    input {
        String datapath
        Directory binsDir
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bins_drep"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate drep
        python /root/microbiome/microbiome/metage_megahit/drep.py -I ~{datapath} --binning ~{binsDir}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage bins_drep \
            --key all \
            --files drep=drep \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bins_drep"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"30"
        memory:"256 GB"
    }
    output {
        Directory drepDir ="drep"
    }
}

task quant_classify {
    input {
        String datapath
        String host
        Directory drepDir
        Directory megahit
        Directory clean_dir
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task quant_classify"
        bash /binscript/quant_classify.sh ~{datapath} ~{clean_dir} ~{drepDir} ~{megahit} ~{host}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage quant_classify \
            --key all \
            --files bin_classfication=bin_classfication quant_bins=quant_bins blobology=blobology \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task quant_classify"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metawrap:v1.79"
        cpu:"72"
        memory:"320 GB"
    }
    output {
        Directory classfiDir ="bin_classfication"
        Directory quantDir ="quant_bins"
        Directory blobologyDir ="blobology"
    }
}

task bins_stats {
    input {
        Directory drepDir
        Directory classfiDir
        Directory quantDir
        Directory blobologyDir
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bins_stats"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/bins_stats.py --blobology ~{blobologyDir} --quantDir ~{quantDir} --drep ~{drepDir} --classfiDir ~{classfiDir}
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bins_stats"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"128 GB"
    }
    output {
        Directory Result ="Result"
    }
}

task prodig_no {
    input {
        String datapath
        Directory megahit
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task prodig_no"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/prodigal_update.py \
            --megahit ~{megahit} \
            --prodigal prodigal \
            --cdhitdir /app/cd-hit-v4.8.1-2019-0228 \
            --threads 60 \
            --chunk-size-mb 200

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage prodigal \
            --key all \
            --files prodigal=prodigal \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task prodig_no"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"72"
        memory:"640 GB"
    }
    output {
        Directory prodigal ="prodigal"
    }
}

task bwa_no {
    input {
        String datapath
        String host
        Directory clean_dir
        Directory prodigal
        Directory dehost_dir
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task bwa_no"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/bwa_update.py \
            -I ~{datapath} \
            --cleandir ~{clean_dir} \
            --host ~{host} \
            --prodigal ~{prodigal} \
            --host_dir ~{dehost_dir} \
            --bowtie bowtie

        for sample in $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt); do
            python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
                -I ~{datapath} \
                --stage bwa \
                --key "$sample" \
                --files bam=bowtie/"$sample".sort.bam \
                --input-samples "$sample" \
                --skip-missing
        done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task bwa_no"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"72"
        memory:"720 GB"
    }
    output {
        Directory bowtie ="bowtie"
    }
}

task tax_anno {
    input {
        String mapdir
        Directory prodigal
        String datapath
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery

        # 固定 diamond block-size 为 8
        BLOCK_SIZE=8
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] diamond block-size: ${BLOCK_SIZE}"

        python /root/microbiome/microbiome/metage_megahit/tax_ano_1_update_V2.py \
            --Annotation Annotation \
            --prodigal ~{prodigal} \
            --dbdir ~{mapdir}/database/NR \
            --megandir /opt/megan7/ \
            --threads 60 \
            --block-size ${BLOCK_SIZE}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage tax_anno \
            --key all \
            --files annotation=Annotation \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"62"
        memory:"720 GB"
    }
    output {
        Directory tax_Annotation ="Annotation"
    }
}

task func_anno {
    input {
        String mapdir
        Directory prodigal
        String datapath
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/func_ano_1_update.py \
            --Annotation Annotation \
            --prodigal ~{prodigal} \
            --dbdir ~{mapdir}/database \
            --emapperdir /app/eggnog-mapper/ \
            --cpu 50 \
            --evalue 1e-5 \
            --prefix func

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage func_anno \
            --key all \
            --files annotation=Annotation \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"62"
        memory:"720 GB"
    }
    output {
        Directory func_Annotation ="Annotation"
    }
}

task anno {
    input {
        String mapdir
        Directory bowtie
        Directory tax_Annotation
        Directory func_Annotation
        String datapath
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery

        mkdir -p Annotation

        python /root/microbiome/microbiome/metage_megahit/tax_ano_2_update.py \
            --Annotation Annotation \
            --dbdir ~{mapdir}/database/NR \
            --bowtie ~{bowtie} \
            --tax_anno ~{tax_Annotation}

        python /root/microbiome/microbiome/metage_megahit/func_ano_2_update.py \
            --Annotation Annotation \
            --dbdir ~{mapdir}/database \
            --mapdir ~{mapdir} \
            --bowtie ~{bowtie} \
            --fun_anno ~{func_Annotation} \
            --workers 4

        python /root/microbiome/microbiome/metage_megahit/gene_func_taxonomy_update.py \
            --Annotation Annotation \
            --func_anno ~{func_Annotation}/func.emapper.annotations

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage anno \
            --key all \
            --files annotation=Annotation \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"512 GB"
    }
    output {
        Directory Annotation ="Annotation"
    }
}

task VCA_anno {
    input {
        String mapdir
        Directory prodigal
        Directory bowtie
        Directory Annotation
        String datapath
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task VCA_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/vfdb_update.py \
            --Annotation ~{Annotation} --prodigal ~{prodigal} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --VFDB VFDB
        python /root/microbiome/microbiome/metage_megahit/CycDB_update.py \
            --Annotation ~{Annotation} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --CycDB CycDB
        python /root/microbiome/microbiome/metage_megahit/ARGs_update.py \
            --Annotation ~{Annotation} --prodigal ~{prodigal} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --ARGdir ARGs

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage VCA_anno \
            --key all \
            --files VFDB=VFDB CycDB=CycDB ARGs=ARGs \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task VCA_anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"512 GB"
    }
    output {
        Directory VFDB ="VFDB"
        Directory CycDB ="CycDB"
        Directory ARGdir ="ARGs"
    }
}

task MBQ_anno {
    input {
        String mapdir
        Directory prodigal
        Directory bowtie
        Directory Annotation
        String datapath
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task MBQ_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/mobileOG_update.py \
            --Annotation ~{Annotation} --prodigal ~{prodigal} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --mobileOGdir mobileOGs
        python /root/microbiome/microbiome/metage_megahit/BacMet2_update.py \
            --Annotation ~{Annotation} --prodigal ~{prodigal} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --BacMet2dir BacMet2
        python /root/microbiome/microbiome/metage_megahit/QS_update.py \
            --Annotation ~{Annotation} --prodigal ~{prodigal} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --QSdir QS

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage MBQ_anno \
            --key all \
            --files mobileOGs=mobileOGs BacMet2=BacMet2 QS=QS \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task MBQ_anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"512 GB"
    }
    output {
        Directory mobileOGs ="mobileOGs"
        Directory BacMet2 ="BacMet2"
        Directory QS ="QS"
    }
}

task tax_base {
    input {
        String datapath
        Directory prodigal
        Directory bowtie
        Directory Annotation
        Directory megahit
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_base"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/megahit_statistics_update.py -I ~{datapath} --megahit ~{megahit} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/prodigal_stats_update.py -I ~{datapath} --prodigal ~{prodigal} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/bwa_stats_update.py -I ~{datapath} --bowtie ~{bowtie} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/tax_stats_update.py -I ~{datapath} --Annotation ~{Annotation} --resdir Result

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage tax_base \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_base"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        Directory Result ="Result"
    }
}

task tax_diff {
    input {
        String datapath
        Directory Annotation
        Directory preResdir
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_diff"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/tax_base_update.py -I ~{datapath} --Annotation ~{Annotation} --resdir Result --pre_resdir ~{preResdir} -j 6
        python /root/microbiome/microbiome/metage_megahit/tax_diff_update.py -I ~{datapath} --resdir Result --tpmdir tax_diff --pre_resdir ~{preResdir}
        python /root/microbiome/microbiome/metage_megahit/alpha_diver_update.py ~{datapath} ~{preResdir} Result
        export ADDR2LINE=addr2line
        set +u
        conda activate lefse
        set -u
        python /root/microbiome/microbiome/metage_megahit/tax_lefse_update.py -I ~{datapath} --res_dir Result --tpmdir tax_diff --pre_resdir ~{preResdir} -t 8

        set +u
        conda activate py39
        set -u
        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage tax_diff \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_diff"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        Directory Result ="Result"
    }
}

task func_base {
    input {
        String datapath
        String mapdir
        Directory CycDB
        Directory ARGdir
        Directory Annotation
        Directory VFDB
        Directory mobileOGs
        Directory BacMet2
        Directory QS
        Directory COG
        Directory MetaCyc
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_base"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_stats_update.py -I ~{datapath} --Annotation ~{Annotation} --dbdir ~{mapdir}/database --resdir Result --func_tmp func_base
        python /root/microbiome/microbiome/metage_megahit/CycDB_stats_update.py -I ~{datapath} --CycDB ~{CycDB} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/ARGs_stats_update.py -I ~{datapath} --ARGdir ~{ARGdir} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/vfdb_stats_update.py -I ~{datapath} --vfdb_dir ~{VFDB} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/mobileOG_stats_update.py -I ~{datapath} --mobileOGdir ~{mobileOGs} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/BacMet2_stats_update.py -I ~{datapath} --BacMet2dir ~{BacMet2} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/QS_stats_update.py -I ~{datapath} --QSdir ~{QS} --resdir Result
        python /root/microbiome/microbiome/metage_megahit/COG_stats_update.py -I ~{datapath} --COG ~{COG} --resdir Result --func_tmp func_base
        python /root/microbiome/microbiome/metage_megahit/MetaCyc_stats_update.py -I ~{datapath} --MetaCyc ~{MetaCyc} --resdir Result --func_tmp func_base
        python /root/microbiome/microbiome/metage_megahit/func_base_update.py -I ~{datapath} --resdir Result --func_tmp func_base

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage func_base \
            --key all \
            --files result=Result func_base=func_base \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_base"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        Directory Result ="Result"
        Directory funcBase ="func_base"
    }
}

task func_diff {
    input {
        String datapath
        Directory funcBase
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_diff"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_diff_update_cog_metacyc.py -I ~{datapath} --resdir Result --func_tmp ~{funcBase} --func_diff func_diff
        export ADDR2LINE=addr2line
        set +u
        conda activate lefse
        set -u
        python /root/microbiome/microbiome/metage_megahit/func_lefse_update.py -I ~{datapath} --resdir Result --func_tmp ~{funcBase} --func_diff func_diff -t 8

        set +u
        conda activate py39
        set -u
        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage func_diff \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_diff"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"320 GB"
    }
    output {
        Directory Result ="Result"
    }
}

task coll_res_ana {
    input {
        String datapath
        String analyse
        String binning
        Directory Res1
        Directory Res2
        Directory Res3
        Directory Res4
        Directory Res5
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_ana"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_update.py \
            --res1 ~{Res1} --res2 ~{Res2} --res3 ~{Res3} --res4 ~{Res4} --res5 ~{Res5} \
            --readme /root/microbiome/microbiome/metage_megahit \
            --outdir Result_update
        python /root/microbiome/microbiome/metage_megahit/pdf2png_update.py -resDir Result_update --zoom 4 -j 8
        python /root/microbiome/microbiome/metage_megahit/get_report_update.py \
            -I ~{datapath} --analyse ~{analyse} --binning ~{binning} --res_dir Result_update --image-mode key
        python /root/microbiome/microbiome/metage_megahit/get_groups_update.py -I ~{datapath} --res Result_update
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans_update.py --res Result_update --font 宋体 -j 8

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage coll_res_ana \
            --key all \
            --files result=Result_update \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task coll_res_ana"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        Directory Result ="Result_update"
    }
}

task coll_res_ana_bins {
    input {
        String datapath
        String analyse
        String binning
        Directory Res1
        Directory Res2
        Directory Res3
        Directory Res4
        Directory Res5
        Directory Res6
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_ana_bins"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_bins_update.py \
            --res1 ~{Res1} --res2 ~{Res2} --res3 ~{Res3} --res4 ~{Res4} --res5 ~{Res5} --res6 ~{Res6} \
            --readme /root/microbiome/microbiome/metage_megahit \
            --outdir Result_update
        python /root/microbiome/microbiome/metage_megahit/pdf2png_update.py -resDir Result_update --zoom 4 -j 8
        python /root/microbiome/microbiome/metage_megahit/get_report_update.py \
            -I ~{datapath} --analyse ~{analyse} --binning ~{binning} --res_dir Result_update --image-mode key
        python /root/microbiome/microbiome/metage_megahit/get_groups_update.py -I ~{datapath} --res Result_update
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans_update.py --res Result_update --font 宋体 -j 8

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage coll_res_ana_bins \
            --key all \
            --files result=Result_update \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task coll_res_ana_bins"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        Directory Result ="Result_update"
    }
}

task coll_res_NOana {
    input {
        String datapath
        String analyse
        String binning
        Directory Res1
        Directory Res2
        Directory Res3
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task coll_res_NOana"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_NOana_update.py \
            --res1 ~{Res1} --res2 ~{Res2} --res3 ~{Res3} \
            --readme /root/microbiome/microbiome/metage_megahit \
            --outdir Result_update
        python /root/microbiome/microbiome/metage_megahit/pdf2png_update.py -resDir Result_update --zoom 4 -j 8
        python /root/microbiome/microbiome/metage_megahit/get_report_update.py \
            -I ~{datapath} --analyse ~{analyse} --binning ~{binning} --res_dir Result_update --image-mode key
        python /root/microbiome/microbiome/metage_megahit/get_groups_update.py -I ~{datapath} --res Result_update
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans_update.py --res Result_update --font 宋体 -j 8

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage coll_res_NOana \
            --key all \
            --files result=Result_update \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task coll_res_NOana"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        Directory Result ="Result_update"
    }
}

task res2json {
    input {
        String datapath
        Directory res_dir
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task res2json"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/res2json_update.py \
            --sorc_path ~{res_dir} -I ~{datapath} --dest_path jsonFile --max-files 20

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage res2json \
            --key all \
            --files jsonFile=jsonFile \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task res2json"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        File jsonFile="jsonFile"
    }
}

task resFile {
    input {
        File report_no
        Directory res_dir
        String projectinfo
    }


    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task resFile"
        bash /root/microbiome/microbiome/metage_megahit/result_manger_update.sh ~{res_dir} Result
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task resFile"
    >>>

    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        Directory respath = "Result"
        File PDFpath = "Result/report.pdf"
        File docxpath = "Result/report.docx"
        File reportNOdir = "~{report_no}"
        File project_info = "~{projectinfo}"
    }
}


task kraken2_anno {
    input {
        Directory cleandir
        String datapath
        Directory kraken2_db
        Int threads = 16
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate kraken2
        python /root/microbiome/microbiome/metage_megahit/kraken2_anno_update.py \
            -i ~{cleandir} \
            -I ~{datapath} \
            --db ~{kraken2_db} \
            -o kraken2_out \
            --threads ~{threads}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage kraken2_anno \
            --key all \
            --files kraken2_out=kraken2_out \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kraken2_anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"~{threads}"
        memory:"128 GB"
    }
    output {
        Directory kraken2_out = "kraken2_out"
    }
}

task kraken2_tax_base {
    input {
        String datapath
        Directory kraken2_out
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_tax_base"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/kraken2_stats_update.py \
            -I ~{datapath} \
            --kraken2_out ~{kraken2_out} \
            --resdir Result

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage kraken2_tax_base \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kraken2_tax_base"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
    }
    output {
        Directory Result = "Result"
    }
}

task kraken2_tax_diff {
    input {
        String datapath
        Directory preResdir
        Int threads = 8
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task kraken2_tax_diff"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/tax_base_update.py \
            -I ~{datapath} \
            --Annotation ~{preResdir}/kraken2_taxonomy \
            --resdir Result \
            --pre_resdir ~{preResdir} \
            -j 6
        python /root/microbiome/microbiome/metage_megahit/tax_diff_update.py \
            -I ~{datapath} \
            --resdir Result \
            --tpmdir tax_diff \
            --pre_resdir ~{preResdir}
        python /root/microbiome/microbiome/metage_megahit/alpha_diver_update.py \
            ~{datapath} ~{preResdir} Result
        set +u
        conda activate lefse
        set -u
        python /root/microbiome/microbiome/metage_megahit/tax_lefse_update.py \
            -I ~{datapath} \
            --res_dir Result \
            --tpmdir tax_diff \
            --pre_resdir ~{preResdir} \
            -t ~{threads}

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage kraken2_tax_diff \
            --key all \
            --files result=Result \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task kraken2_tax_diff"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"~{threads}"
        memory:"64 GB"
    }
    output {
        Directory Result = "Result"
    }
}

task COG_anno {
    input {
        String mapdir
        Directory prodigal
        Directory bowtie
        Directory Annotation
        String datapath
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task COG_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/COG_update.py \
            --Annotation ~{Annotation} --prodigal ~{prodigal} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --COGdir COG

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage COG_anno \
            --key all \
            --files COG=COG \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task COG_anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"512 GB"
    }
    output {
        Directory COG = "COG"
    }
}

task MetaCyc_anno {
    input {
        String mapdir
        Directory prodigal
        Directory bowtie
        Directory Annotation
        String datapath
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task MetaCyc_anno"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/MetaCyc_update.py \
            --Annotation ~{Annotation} --prodigal ~{prodigal} --bowtie ~{bowtie} --dbdir ~{mapdir}/database --MetaCycdir MetaCyc

        python /root/microbiome/microbiome/metage_megahit/sample_double_check.py record-stage \
            -I ~{datapath} \
            --stage MetaCyc_anno \
            --key all \
            --files MetaCyc=MetaCyc \
            --input-samples $(awk 'NR>1 {print $2}' ~{datapath}/sample.txt | tr '\n' ' ') \
            --merged --no-md5
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task MetaCyc_anno"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"512 GB"
    }
    output {
        Directory MetaCyc = "MetaCyc"
    }
}

task ref_assembly {
    input {
        String datapath
        Directory cleandir
        String ref_sample
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task ref_assembly"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/ref_assembly_update.py \
            -I ~{datapath} \
            --cleandir ~{cleandir} \
            --ref_sample ~{ref_sample} \
            -o ref_assembly \
            --threads 24
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task ref_assembly"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"320 GB"
    }
    output {
        Directory ref_assembly_dir = "ref_assembly"
        File ref_fasta = "ref_assembly/ref.fa"
    }
}

task ref_mapping {
    input {
        String datapath
        Directory cleandir
        File ref_fasta
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task ref_mapping"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/ref_mapping_update.py \
            -I ~{datapath} \
            --cleandir ~{cleandir} \
            --ref_fasta ~{ref_fasta} \
            -o ref_mapping \
            --threads 16
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task ref_mapping"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"256 GB"
    }
    output {
        Directory ref_mapping_dir = "ref_mapping"
    }
}

task snp_calling {
    input {
        String datapath
        Directory bamdir
        File ref_fasta
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task snp_calling"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/snp_calling_update.py \
            -I ~{datapath} \
            --bamdir ~{bamdir} \
            --ref_fasta ~{ref_fasta} \
            -o snp_calling \
            --threads 8
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task snp_calling"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"16"
        memory:"128 GB"
    }
    output {
        Directory snp_dir = "snp_calling"
    }
}

task tax_unifrac {
    input {
        String datapath
        File tax_tree
        Directory resdir
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task tax_unifrac"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/tax_unifrac_update.py \
            -I ~{datapath} \
            --tree ~{tax_tree} \
            --resdir ~{resdir} \
            --outdir tax_unifrac
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task tax_unifrac"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"128 GB"
    }
    output {
        Directory tax_unifrac_out = "tax_unifrac"
    }
}

task func_unifrac {
    input {
        String datapath
        File func_tree
        Directory funcBase
    }

    command <<<
        set -euo pipefail
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Start task func_unifrac"
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_unifrac_update.py \
            -I ~{datapath} \
            --tree ~{func_tree} \
            --func_tmp ~{funcBase} \
            --outdir func_unifrac
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] End task func_unifrac"
    >>>
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"128 GB"
    }
    output {
        Directory func_unifrac_out = "func_unifrac"
    }
}
