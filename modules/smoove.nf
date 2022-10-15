#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process smoove {
	debug true
	// smoove makes its out outdir
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'

    // Run with container
	container "${params.smoove__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	path("smoove/*-smoove.genotyped.vcf") 			, emit: smoove_vcf
	path("smoove/*-smoove.genotyped.vcf.gz.csi") 	, emit: smoove_vcf_csi
	path("smoove/*.split.bam") 						, emit: smoove_split
	path("smoove/*.split.bam.csi") 					, emit: smoove_split_csi
	path("smoove/*.disc.bam")						, emit: smoove_disc
	path("smoove/*.disc.bam.csi")					, emit: smoove_disc_csi
	path("smoove/*.histo")							, emit: smoove_histo
	path("SmooveVCF_path")							, emit: smoove_VCF
	
	script:
	// suggest printing stats as per: https://github.com/brwnj/smoove-nf/blob/master/main.nf 
	"""
	smoove call --name ${sampleID} \
	--fasta ${params.ref} \
	--outdir smoove \
	-p ${task.cpus} \
	--genotype ${bam}

	gunzip smoove/${sampleID}-smoove.genotyped.vcf.gz

	#collect file name for merging 
	echo smoove/${sampleID}-smoove.genotyped.vcf > SmooveVCF_path 
	"""
} 
