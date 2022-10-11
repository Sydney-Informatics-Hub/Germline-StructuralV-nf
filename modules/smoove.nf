#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process smoove {
	debug true
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'

	// resource parameters. Developer suggests good scaling up to 2-3 CPUs
    cpus "${params.smooveCPUs}"

        // Run with container
	container "${params.smoove__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("smoove/*-smoove.genotyped.vcf.gz")
	tuple val(sampleID), path("smoove/*-smoove.genotyped.vcf.gz.csi")
	tuple val(sampleID), path("smoove/*.split.bam")
	tuple val(sampleID), path("smoove/*.split.bam.csi")
	tuple val(sampleID), path("smoove/*.disc.bam") 
	tuple val(sampleID), path("smoove/*.disc.bam.csi")
	tuple val(sampleID), path("smoove/*.histo")
	
	script:
	// suggest printing stats as per: https://github.com/brwnj/smoove-nf/blob/master/main.nf 
	"""
	smoove call --name ${sampleID} \
	--fasta ${params.ref} \
	--outdir smoove \
	-p ${params.smooveCPUs} \
	--genotype ${bam}
	"""
} 
