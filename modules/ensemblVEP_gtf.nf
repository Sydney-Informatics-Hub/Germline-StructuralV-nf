#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Run variant effect predictor with cache
process vep_GTFrun {
    debug false
    publishDir "${params.outDir}/${sampleID}/vep", mode: 'copy'
	container "${params.vep__container}"
    
    input:
    tuple val(sampleID), path(mergedVCF)
    path(ref)
    path(VEPgtf_gz)
    path(VEPgtf_tbi)
    path(VEPcache)

    output:
    tuple val(sampleID), path("*"), emit: gtfVEP
    
    script:
    """
    vep -i ${sampleID}_merged.vcf --vcf \
        -o ${sampleID}_gtf_VEPannotated.vcf \
        --stats_file ${sampleID}_gtf_VEP.summary.html \
        --fasta ${params.ref} --gtf ${params.gtf} \
        --cache --dir_cache ${params.VEPcache} \
        --format vcf \
        --fork ${task.cpus} \
        --symbol --ccds --biotype
    """
}
