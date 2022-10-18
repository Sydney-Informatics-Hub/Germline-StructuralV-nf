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
	path("smoove/${sampleID}-smoove.genotyped.vcf.gz")		, emit: smoove_geno
	path("smoove/${sampleID}-smoove.genotyped.vcf.gz.csi")	, emit: smoove_geno_csi
	path("smoove/${sampleID}.split.bam")					, emit: smoove_split, optional: true
	path("smoove/${sampleID}.split.bam.csi")				, emit: smoove_split_csi, optional: true
	path("smoove/${sampleID}.disc.bam") 					, emit: smoove_disc, optional: true
	path("smoove/${sampleID}.disc.bam.csi")					, emit: smoove_disc_csi, optional: true
	path("smoove/${sampleID}.histo")						, emit: smoove_histo, optional: true
	
	script:
	// TODO: suggest printing stats as per: https://github.com/brwnj/smoove-nf/blob/master/main.nf 
	"""
	smoove call --name ${sampleID} \
	--fasta ${params.ref} \
	--outdir smoove \
	--processes 4 \
	--genotype ${bam}

	"""
} 

process rehead_smoove {
	debug true 
	publishDir "${params.outDir}/${sampleID}/smoove", mode: 'copy'
	container "${params.bcftools__container}"

	input:
	//TODO: work out how pass input without associating a bam to the sampleID?
	tuple val(sampleID), path(bam)
	path(smoove_geno)
		
	output:
	path("Smoove_${sampleID}.vcf")	, emit: Smoove_finalVCF	
		
	script:
	"""
	# create new header for merged vcf
	printf "${sampleID}_smoove\n" > ${sampleID}_rehead_smoove.txt

	# replace sampleID with caller_sample for merging 	
	bcftools reheader \
		${sampleID}-smoove.genotyped.vcf.gz \
		-s ${sampleID}_rehead_smoove.txt \
		-o Smoove_${sampleID}.vcf
	
	#clean up
	#rm -r ${sampleID}_rehead_smoove.txt
	"""
}