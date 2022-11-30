#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// prepare .gtf for VEP 
process vep_GTFprep {
    debug false
    cpus 1
	container "${params.bcftools__container}"

    input:
    path(params.gtf)

    output:
    path("*.gz"),   emit: VEPgtf_gz
    path("*.tbi"),  emit: VEPgtf_tbi
    
    script:
    """
    grep -v "#" ${params.gtf} | \
        sort -k1,1 -k4,4n -k5,5n -t'\t' \
        > sorted.gtf 

    # bgzip sorted gtf
    bgzip -c sorted.gtf > sorted.gtf.gz 
        
    # index gtf
    tabix sorted.gtf.gz
    """
}