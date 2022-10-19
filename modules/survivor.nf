#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process survivor_merge {
	debug true
	publishDir "${params.outDir}/${sampleID}/survivor", mode: 'copy'
	container "${params.survivor__container}"
	
	input:
	tuple val(sampleID), path("*") 
	file(merge)

	output:
	tuple val(sampleID), path("*_merged.vcf")

    script:
    """
	#SURVIVOR_max_dist=1000 	# Max distance between breakpoints (0-1 percent of length, 1- number of bp)
	#SURVIVOR_callers=1 		# Minimum number of supporting caller
	#SURVIVOR_type=0			# Take the type into account (1==yes, else no)
	#SURVIVOR_strand=0			# Take the strands of SVs into account (1==yes, else no)
	#SURVIVOR_dist=0 			# INACTIVE Estimate distance based on the size of SV (1==yes, else no)
	#SURVIVOR_len=30			# Minimum size of SVs to be taken into account.

	SURVIVOR merge ${mergelist} 1000 1 0 0 0 30 \
	${sampleID}_merged.vcf
	"""
}