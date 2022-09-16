#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process tiddit {
	debug true
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'

	// resource parameters. Cannot scale
    cpus 1

        // Run with container
	container "${params.tiddit__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("*.vcf")
	tuple val(sampleID), path("*ploidies.tab")
	
	script:
	// will need to add option for additional flags. See manta script for example
	"""
	tiddit \
	--sv \
	--bam ${bam} \
	--ref ${params.ref} \
	-o tiddit/${sampleID}
	"""
} 
