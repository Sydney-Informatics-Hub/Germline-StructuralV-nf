#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// run smoove structural variant detection
process smoove {
	debug true
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'
    cpus "${task.cpus}"
	container "${params.smoove__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("smoove/${sampleID}-smoove.genotyped.vcf.gz")		, emit: smoove_geno
	tuple val(sampleID), path("smoove/${sampleID}-smoove.genotyped.vcf.gz.csi")	, emit: smoove_geno_csi
	tuple val(sampleID), path("smoove/${sampleID}.split.bam")					, emit: smoove_split, 		optional: true
	tuple val(sampleID), path("smoove/${sampleID}.split.bam.csi")				, emit: smoove_split_csi, 	optional: true
	tuple val(sampleID), path("smoove/${sampleID}.disc.bam") 					, emit: smoove_disc, 		optional: true
	tuple val(sampleID), path("smoove/${sampleID}.disc.bam.csi")				, emit: smoove_disc_csi,	optional: true
	tuple val(sampleID), path("smoove/${sampleID}.histo")						, emit: smoove_histo, 		optional: true
	
	script:
	// TODO: will need to add option for additional flags
	"""
	smoove call --name ${sampleID} \
	--fasta ${params.ref} \
	--outdir smoove \
	--processes 4 \
	--genotype ${bam}
	"""
} 

// rehead smoove genotyped vcf for merging 
process rehead_smoove {
	debug true 
	publishDir "${params.outDir}/${sampleID}/smoove", mode: 'copy'
	container "${params.bcftools__container}"

	input:
	tuple val(sampleID), path(smoove_geno)
		
	output:
	path("Smoove_${sampleID}.vcf")	, emit: finalVCF	
		
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