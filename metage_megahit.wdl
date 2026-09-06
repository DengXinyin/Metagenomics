workflow metage_megahit2 {
    String datapath="/cephfs_data/genostack_v3/genostack_php/public_file_data/metagenome-rawdata/test/data"
    String rawdatapath="/cephfs_data/genostack_v3/genostack_php/public_file_data/metagenome-rawdata/test/rawdata"
    String host="none"
    String mapdir="/cephfs_data/genostack_v3/genostack_php/public_file_data/metagenome-DB"
    String binning='no'
    String analyse='yes'
    String report_no='/cephfs_data/genostack_v3/genostack_php/project_data/703/20240100993/report_no.txt'
    String project=""
    String isbwa="yes"
    String Taskid="2711c93b-6a8b-4a2d-b2f8-657397d05307"
    # String clean_dir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-kneaddata/execution/cleandata"
    # String megahitdir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-megahit_dehost/execution/megahit"
    # String prodigdir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-prodig/execution/prodigal"
    # String bingdir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-kneaddata/execution/cleandata"
    # String bwadir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-bwa/execution/bowtie"
    # String anno_dir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-anno/execution/Annotation"
    # String func_annodir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-func_anno/execution/Annotation"
    # String tax_annodir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-tax_anno/execution/Annotation"
    # String ARGsdir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-VCA_anno/execution/ARGs"
    # String CycDBdir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-VCA_anno/execution/CycDB"
    # String VFDBdir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-VCA_anno/execution/VFDB"
    # String BacMet2_annodir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-MBQ_anno/execution/BacMet2"
    # String QS_annodir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-MBQ_anno/execution/QS"
    # String mobileOG_annodir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-MBQ_anno/execution/mobileOGs"
    # String kneaddatadir="/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/2711c93b-6a8b-4a2d-b2f8-657397d05307/call-kneaddata/execution/Result"


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
                checkDir=check_input_with_raw.result
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
                clean_dir=kneaddata_no.cleandir,
                host=host
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
                mapdir=mapdir
        }

        call func_anno {
            input:
                prodigal=prodig_no.prodigal,
                mapdir=mapdir
        }

        call anno {
            input:
                bowtie=bwa_no.bowtie,
                tax_Annotation=tax_anno.tax_Annotation,
                func_Annotation=func_anno.func_Annotation,
                mapdir=mapdir
        }

        call VCA_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=prodig_no.prodigal,
                bowtie=bwa_no.bowtie,
                mapdir=mapdir
        }

        call MBQ_anno {
            input:
                Annotation=anno.Annotation,
                prodigal=prodig_no.prodigal,
                bowtie=bwa_no.bowtie,
                mapdir=mapdir
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
            QS=select_first([MBQ_anno.QS, deal_parameter.QS_annodir])
    }

    if (analyse == 'yes'){
        call tax_diff {
            input:
                datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                preResdir=tax_base.Result,
                Annotation=select_first([anno.Annotation, deal_parameter.anno_dir])
        }
        call func_diff {
            input:
                datapath=select_first([check_input_with_raw.result, check_input_no_raw.result]),
                funcBase=func_base.funcBase
        }
        if (binning == 'yes'){
            call coll_res_ana_bins {
                input:
                    mapdir=mapdir,
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
                    mapdir=mapdir,
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
                mapdir=mapdir,
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
        File respath = resFile.respath
        File pdfFile = resFile.PDFpath
        File wordFile = resFile.docxpath
        File jsonpath = res2json.jsonFile
        File reportNo = resFile.reportNOdir
        File infoFile = resFile.project_info
    }

}

task deal_parameter{
    String taskid
    # String inclean_dir
    # String inmegahitdir
    # String inprodigdir
    # String inbingdir
    # String inbwadir
    # String infunc_annodir
    # String intax_annodir
    # String inARGsdir
    # String inCycDBdir
    # String inVFDBdir
    # String inBacMet2_annodir
    # String inQS_annodir
    # String inmobileOG_annodir
    # String inanno_dir
    # String inkneaddatadir

    command{

        echo "Passing parameters"
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"20 GB"
        # lable:"node6"
    }
    output {
        File clean_dir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-kneaddata/execution/cleandata"
        File megahitdir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-megahit_dehost/execution/megahit"
        File prodigdir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-prodig/execution/prodigal"
        File bingdir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-kneaddata/execution/cleandata"
        File bwadir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-bwa/execution/bowtie"
        File func_annodir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-func_anno/execution/Annotation"
        File anno_dir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-anno/execution/Annotation"
        File tax_annodir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-tax_anno/execution/Annotation"
        File ARGsdir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-VCA_anno/execution/ARGs"
        File CycDBdir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-VCA_anno/execution/CycDB"
        File VFDBdir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-VCA_anno/execution/VFDB"
        File BacMet2_annodir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-MBQ_anno/execution/BacMet2"
        File QS_annodir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-MBQ_anno/execution/QS"
        File mobileOG_annodir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-MBQ_anno/execution/mobileOGs"
        File kneaddatadir = "/cephfs_data/genostack_v3/genostack_cromwell/cromwell-executions/metage_megahit/${taskid}/call-kneaddata/execution/Result"
        # File clean_dir = "${inclean_dir}"
        # File megahitdir = "${inmegahitdir}"
        # File prodigdir = "${inprodigdir}"
        # File bingdir = "${inbingdir}"
        # File bwadir = "${inbwadir}"
        # File func_annodir = "${infunc_annodir}"
        # File anno_dir = "${inanno_dir}"
        # File tax_annodir = "${intax_annodir}"
        # File ARGsdir = "${inARGsdir}"
        # File CycDBdir = "${inCycDBdir}"
        # File VFDBdir = "${inVFDBdir}"
        # File BacMet2_annodir = "${inBacMet2_annodir}"
        # File QS_annodir = "${inQS_annodir}"
        # File mobileOG_annodir = "${inmobileOG_annodir}"
        # File kneaddatadir = "${inkneaddatadir}"
    }
}

task check_input_no_raw{
    String dataDir
    String project_info
    # String fastq_dir
    command{
        mkdir metadatadir
        cp ${project_info} metadatadir/
        echo "Running fastq mapping validation..."
        python /root/microbiome/microbiome/metage_megahit/dealdata.py -indir ${dataDir} -outdir metadatadir
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"20 GB"
        # lable:"node6"
    }
    output {
        File result="metadatadir"
    }
}
task check_input_with_raw{
    String dataDir
    String fastq_dir
    String project_info
    command{
        echo "Running fastq mapping validation..."

        mkdir metadatadir
        cp ${project_info} metadatadir/
        python /root/microbiome/microbiome/metage_megahit/dealdata.py -indir ${dataDir} -outdir metadatadir

        python /root/microbiome/microbiome/metage_megahit/check_fastq_mapping.py \
            ${fastq_dir} \
            metadatadir/sample.txt \
            metadatadir/sample-metadata.tsv
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"20 GB"
        # lable:"node6"
    }
    output {
        File result="metadatadir"
    }
}

task kneaddata_no {
    String datapath
    String rawdatapath
    String host
    String mapdir
    String checkDir

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        ls ${checkDir}
        python /root/microbiome/microbiome/metage_megahit/Kneaddata.py -i ${rawdatapath} -I ${datapath} --host ${host} --mapdir ${mapdir}/database/kneaddata_database
        # 当 host 为 none 时，Kneaddata.py 不会创建 de_host 目录，但 WDL 输出需要该目录
        if [ "${host}" = "none" ] && [ ! -d de_host ]; then mkdir -p de_host; fi
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"320 GB"
        # lable:"node6"
    }
    output {
        File cleandir="cleandata"
        File Result="Result"
        File dohost_dir="de_host"
    }
}

task megahit_no {
    String datapath
    String host
    File clean_dir
    File dehost_dir

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/megahit.py -I ${datapath} --cleandir ${clean_dir} --host ${host}  --host_dir ${dehost_dir}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"96"
        memory:"720 GB"
        # lable:"node6"
    }
    output {
        File megahit="megahit"
    }
}

task bins {
    String datapath
    File megahit

    command {
        bash /binscript/binning.sh ${datapath} ${megahit} binnings
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metawrap:v1.79"
        cpu:"72"
        memory:"256 GB"
        # lable:"node6"
    }
    output {
        File binsDir="binnings"
    }
}

task bins_drep {
    String datapath
    File binsDir

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate drep
        python /root/microbiome/microbiome/metage_megahit/drep.py -I ${datapath} --binning ${binsDir}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"30"
        memory:"256 GB"
        # lable:"node6"
    }
    output {
        File drepDir="drep"
    }
}

task quant_classify {
    String datapath
    String host
    File drepDir
    File megahit
    File clean_dir

    command {
        bash /binscript/quant_classify.sh ${datapath} ${clean_dir} ${drepDir} ${megahit} ${host}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metawrap:v1.79"
        cpu:"72"
        memory:"320 GB"
        # lable:"node6"
    }
    output {
        File classfiDir="bin_classfication"
        File quantDir="quant_bins"
        File blobologyDir="blobology"
    }
}

task bins_stats {
    File drepDir
    File classfiDir
    File quantDir
    File blobologyDir

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/bins_stats.py --blobology ${blobologyDir} --quantDir ${quantDir} --drep ${drepDir} --classfiDir ${classfiDir}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"12"
        memory:"128 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
    }
}

task prodig_no {
    String datapath
    String host
    File clean_dir
    File megahit

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate megahit
        python /root/microbiome/microbiome/metage_megahit/prodigal.py --megahit ${megahit} --cdhitdir /app/cd-hit-v4.8.1-2019-0228
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"72"
        memory:"640 GB"
        # lable:"node6"
    }
    output {
        File prodigal="prodigal"
    }
}

task bwa_no {
    String datapath
    String host
    File clean_dir
    File prodigal
    File dehost_dir
    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/bwa.py -I ${datapath} --cleandir ${clean_dir} --host ${host} --prodigal ${prodigal} --host_dir ${dehost_dir} --host_dir ${dehost_dir}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"72"
        memory:"720 GB"
        # lable:"node6"
    }
    output {
        File bowtie="bowtie"
    }
}

task tax_anno {
    String mapdir
    File prodigal

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/tax_ano_1.py --prodigal ${prodigal} --dbdir ${mapdir}/database/NR --megandir /opt/megan7/
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"62"
        memory:"720 GB"
        # lable:"node6"
    }
    output {
        File tax_Annotation="Annotation"
    }
}

task func_anno {
    String mapdir
    File prodigal

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/func_ano_1.py --prodigal ${prodigal} --dbdir ${mapdir}/database --emapperdir /app/eggnog-mapper/
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"62"
        memory:"720 GB"
        # lable:"node6"
    }
    output {
        File func_Annotation="Annotation"
    }
}

task anno {
    String mapdir
    File bowtie
    File tax_Annotation
    File func_Annotation

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/tax_ano_2.py --tax_anno ${tax_Annotation} --dbdir ${mapdir}/database/NR --bowtie ${bowtie}
        python /root/microbiome/microbiome/metage_megahit/func_ano_2.py --fun_anno ${func_Annotation} --dbdir ${mapdir}/database --mapdir ${mapdir} --bowtie ${bowtie}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"512 GB"
        # lable:"node6"
    }
    output {
        File Annotation="Annotation"
    }
}

task VCA_anno {
    String mapdir
    File prodigal
    File bowtie
    File Annotation

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/vfdb.py --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database
        python /root/microbiome/microbiome/metage_megahit/CycDB.py --Annotation ${Annotation} --bowtie ${bowtie} --dbdir ${mapdir}/database
        python /root/microbiome/microbiome/metage_megahit/ARGs.py --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"512 GB"
        # lable:"node6"
    }
    output {
        File VFDB="VFDB"
        File CycDB="CycDB"
        File ARGdir="ARGs"
    }
}

task MBQ_anno {
    String mapdir
    File prodigal
    File bowtie
    File Annotation

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate biobakery
        python /root/microbiome/microbiome/metage_megahit/mobileOG.py --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database
        python /root/microbiome/microbiome/metage_megahit/BacMet2.py --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database
        python /root/microbiome/microbiome/metage_megahit/QS.py --Annotation ${Annotation} --prodigal ${prodigal} --bowtie ${bowtie} --dbdir ${mapdir}/database
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"512 GB"
        # lable:"node6"
    }
    output {
        File mobileOGs="mobileOGs"
        File BacMet2="BacMet2"
        File QS="QS"
    }
}

task tax_base {
    String datapath
    File prodigal
    File bowtie
    File Annotation
    File megahit

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/megahit_statistics.py -I ${datapath} --megahit ${megahit}
        python /root/microbiome/microbiome/metage_megahit/prodigal_stats.py -I ${datapath} --prodigal ${prodigal}
        python /root/microbiome/microbiome/metage_megahit/bwa_stats.py -I ${datapath} --bowtie ${bowtie}
        python /root/microbiome/microbiome/metage_megahit/tax_stats.py -I ${datapath} --Annotation ${Annotation}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"320 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
    }
}

task tax_diff {
    String datapath
    File Annotation
    File preResdir

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/tax_base.py -I ${datapath} --Annotation ${Annotation} --pre_resdir ${preResdir}
        python /root/microbiome/microbiome/metage_megahit/tax_diff.py -I ${datapath} --pre_resdir ${preResdir}
        /root/anaconda3/envs/r/bin/Rscript /root/microbiome/microbiome/metage_megahit/alpha_diver.R ${datapath}  ${preResdir}/ Result
        conda activate lefse
        python /root/microbiome/microbiome/metage_megahit/tax_lefse.py -I ${datapath} --pre_resdir ${preResdir}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"320 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
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

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_stats.py -I ${datapath} --Annotation ${Annotation} --dbdir ${mapdir}/database
        python /root/microbiome/microbiome/metage_megahit/CycDB_stats.py -I ${datapath} --CycDB ${CycDB}
        python /root/microbiome/microbiome/metage_megahit/ARGs_stats.py -I ${datapath} --ARGdir ${ARGdir}
        python /root/microbiome/microbiome/metage_megahit/vfdb_stats.py -I ${datapath} --VFDB ${VFDB}
        python /root/microbiome/microbiome/metage_megahit/mobileOG_stats.py -I ${datapath} --mobileOGdir ${mobileOGs}
        python /root/microbiome/microbiome/metage_megahit/BacMet2_stats.py -I ${datapath} --BacMet2dir ${BacMet2}
        python /root/microbiome/microbiome/metage_megahit/QS_stats.py -I ${datapath} --QSdir ${QS}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"320 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
        File funcBase="func_base"
    }
}

task func_diff {
    String datapath
    File funcBase

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/func_base.py -I ${datapath} --func_tmp ${funcBase}
        python /root/microbiome/microbiome/metage_megahit/func_diff.py -I ${datapath} --func_tmp ${funcBase}
        conda activate lefse
        python /root/microbiome/microbiome/metage_megahit/func_lefse.py -I ${datapath} --func_tmp ${funcBase}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"32"
        memory:"320 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
    }
}

task coll_res_ana {
    String mapdir
    String datapath
    String analyse
    String binning
    File Res1
    File Res2
    File Res3
    File Res4
    File Res5

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res.py --res1 ${Res1} --res2 ${Res2} --res3 ${Res3} --res4 ${Res4} --res5 ${Res5} --readme /root/microbiome/microbiome/metage_megahit
        python /root/microbiome/microbiome/metage_megahit/pdf2png.py -resDir Result/
        python /root/microbiome/microbiome/metage_megahit/get_report.py -I ${datapath} --res_dir Result/ --micro_docx_path /root/microbiome/microbiome/metage_megahit --analyse ${analyse} --binning ${binning}
        python /root/microbiome/microbiome/metage_megahit/get_groups.py -I ${datapath} --res Result/
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans.py --res Result/
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
    }
}

task coll_res_ana_bins {
    String mapdir
    String datapath
    String analyse
    String binning
    File Res1
    File Res2
    File Res3
    File Res4
    File Res5
    File Res6

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_bins.py --res1 ${Res1} --res2 ${Res2} --res3 ${Res3} --res4 ${Res4} --res5 ${Res5} --res6 ${Res6} --readme /root/microbiome/microbiome/metage_megahit
        python /root/microbiome/microbiome/metage_megahit/pdf2png.py -resDir Result/
        python /root/microbiome/microbiome/metage_megahit/get_report.py -I ${datapath} --res_dir Result/ --micro_docx_path /root/microbiome/microbiome/metage_megahit --analyse ${analyse} --binning ${binning}
        python /root/microbiome/microbiome/metage_megahit/get_groups.py -I ${datapath} --res Result/
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans.py --res Result/
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
    }
}

task coll_res_NOana {
    String mapdir
    String datapath
    String analyse
    String binning
    File Res1
    File Res2
    File Res3

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/collect_res_NOana.py --res1 ${Res1} --res2 ${Res2} --res3 ${Res3} --readme /root/microbiome/microbiome/metage_megahit
        python /root/microbiome/microbiome/metage_megahit/pdf2png.py -resDir Result/
        python /root/microbiome/microbiome/metage_megahit/get_report.py -I ${datapath} --res_dir Result/ --micro_docx_path /root/microbiome/microbiome/metage_megahit --analyse ${analyse} --binning ${binning}
        python /root/microbiome/microbiome/metage_megahit/get_groups.py -I ${datapath} --res Result/
        python /root/microbiome/microbiome/metage_megahit/xlsx_trans.py --res Result/
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
        # lable:"node6"
    }
    output {
        File Result="Result"
    }
}

task res2json {
    String datapath
    File res_dir

    command {
        source /root/anaconda3/etc/profile.d/conda.sh
        conda activate py39
        python /root/microbiome/microbiome/metage_megahit/res2json.py --sorc_path ${res_dir} -I ${datapath}
    }
    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
        # lable:"node6"
    }
    output {
        File jsonFile="jsonFile"
    }
}

task resFile {
    File report_no
    File res_dir
    String projectinfo

    command {
        bash /root/microbiome/microbiome/metage_megahit/result_manger.sh ${res_dir}
    }

    runtime {
        docker:"192.168.30.202:23099/metage_megahit/metage:v2.87"
        cpu:"24"
        memory:"128 GB"
        # lable:"node6"
    }
    output {
        File respath = "Result"
        File PDFpath = "Result/report.pdf"
        File docxpath = "Result/report.docx"
        File reportNOdir = "${report_no}"
        File project_info = "${projectinfo}"
    }
}