#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// download cache 
process VEPcache_prep {
    debug false
    publishDir "${params.outDir}/${sampleID}/vep", mode: 'copy'
    cpus 4 //"${task.cpus}"
	container "${params.vep__container}"
    
    input:

    output:
    tuple val(sampleID), path("*"), emit: cacheVEP
    
    script:
    """
    # make cachedir 
    mkdir -p local_vep_cache_dir_tmp
    
    # download cache
    wget -P local_vep_cache_dir_tmp \
        ftp://ftp.ensembl.org/pub/release-108/variation/indexed_vep_cache/homo_sapiens_vep_108_GRCh38.tar.gz
    """
}

// run variant effect predictor 
process VEPcache_run {
    debug false
    publishDir "${params.outDir}/${sampleID}/annotations", mode: 'copy'
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
        --cache --dir_cache ${params.VEPcache} \
        --format vcf \
        --af_gnomadg \
        --symbol --ccds --biotype \
        --check_svs --overlaps 
    """
}

// run variant effect predictor with cache
process VEPgtf_run {
    debug false
    publishDir "${params.outDir}/${sampleID}/annotations", mode: 'copy'
	container "${params.vep__container}"
    
    input:
    tuple val(sampleID), path(mergedVCF)
    path(ref)
    path(VEPgtf_gz)
    path(VEPgtf_tbi)
    path(VEPcache)

    output:
    tuple val(sampleID), path("*")
    
    script:
    """
    vep -i ${sampleID}_merged.vcf --vcf \
        -o ${sampleID}_gtf_VEPannotated.vcf \
        --stats_file ${sampleID}_gtf_VEP.summary.html \
        --fasta ${params.ref} --gtf ${params.gtf} \
        --cache --dir_cache ${params.VEPcache} \
        --format vcf \
        --symbol --ccds --biotype
    """
}
