#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process survivor_merge {
	debug true
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'

	// Run with container
	container "${params.survivor__container}"
	
	input:
	tuple val(sampleID), path(smooveVCF), path(mantaVCF), path(tidditVCF) 
	
	output:
	tuple val(sampleID), path("*.vcf")

	script:
	"""
	# Unzip all the vcfs- SURVIVOR can't handle .gz
	

	# Make vcf list 

	# Merge caller vcfs 

	# Tidy up 

	"""
} 
