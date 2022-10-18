#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process smoove {
	debug true
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'

	// resource parameters. Developer suggests good scaling up to 2-3 CPUs
    cpus "${task.cpus}"

        // Run with container
	container "${params.smoove__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	path("smoove/*-smoove.genotyped.vcf.gz")
	path("smoove/*-smoove.genotyped.vcf.gz.csi")
	path("smoove/*.split.bam")
	path("smoove/*.split.bam.csi")
	path("smoove/*.disc.bam") 
	path("smoove/*.disc.bam.csi")
	path("smoove/*.histo")
	
	script:
	// suggest printing stats as per: https://github.com/brwnj/smoove-nf/blob/master/main.nf 
	"""
	smoove call --name ${sampleID} \
	--fasta ${params.ref} \
	--outdir smoove \
	--processes 4 \
	--genotype ${bam}
	"""
} 
