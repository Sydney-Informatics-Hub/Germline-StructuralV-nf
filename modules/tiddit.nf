#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// run tiddit structural variant detection
process tiddit_sv {
	debug true
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'

	// resource parameters. Cannot scale
    cpus 4

    // Run with container
	container "${params.tiddit__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("*.vcf")
	tuple val(sampleID), path("*.ploidies.tab")
	tuple val(sampleID), path("*_tiddit")
	
	script:
	// will need to add option for additional flags. See manta script for example
	"""
	tiddit \
	--sv \
	--bam ${bam} \
	--ref ${params.ref} \
	-o ${sampleID}_sv \
	--threads 2
	"""
}

// calculate coverage of bam files 
process tiddit_cov {
	debug true
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'

	// resource parameters. Cannot scale
    cpus 4

    // Run with container
	container "${params.tiddit__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("*.bed")
	
	script:
	// will need to add option for additional flags. See manta script for example
	"""
	tiddit \
	--cov \
	--bam ${bam} \
	--ref ${params.ref} \
	-o ${sampleID}_cov \
	"""

}