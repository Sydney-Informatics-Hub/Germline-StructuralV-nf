#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// download cache 
process vep_cacheprep {
    debug false
    publishDir "${params.outDir}/${sampleID}/vep", mode: 'copy'
    container "${params.vep__container}"
    
    input:

    output:
    tuple val(sampleID), path("*"), emit: cacheVEP
    
    script:
    """
    # make cachedir 
    mkdir -p local_vep_cache_dir_tmp
    
    # download cache
    wget -P VEP_localCache \
        ftp://ftp.ensembl.org/pub/release-108/variation/indexed_vep_cache/homo_sapiens_vep_108_GRCh38.tar.gz
    """
}

// run variant effect predictor 
process vep_cacherun {
    debug false
    publishDir "${params.outDir}/${sampleID}/vep", mode: 'copy'
	container "${params.vep__container}"
    
    input:
    tuple val(sampleID), path(mergedVCF)
    path(VEPcache)

    output:
    tuple val(sampleID), path("*")
    
    script:
    """
    vep -i ${sampleID}_merged.vcf --vcf \
        -o ${sampleID}_cache_VEPannotated.vcf \
        --stats_file ${sampleID}_cache_VEP.summary.html \
        --offline \
        --cache --dir_cache ${params.VEPcache} \
        --format vcf \
        --fork ${task.cpus} \
        --af_gnomadg \
        --symbol --ccds --biotype \
        --check_svs --overlaps 
    """
}
