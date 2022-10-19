#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// run tiddit structural variant detection
process tiddit_sv {
	debug true
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'
	container "${params.tiddit__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("Tiddit_${sampleID}_sv.vcf") 	, emit: tiddit_vcf
	tuple val(sampleID), path("${sampleID}_sv.ploidies.tab") , emit: tiddit_ploidy
	tuple val(sampleID), path("${sampleID}_sv_tiddit") 		, emit: tiddit_workdir
	
	script:
	// TODO: will need to add option for additional flags
	"""
	tiddit \
	--sv \
	--bam ${bam} \
	--ref ${params.ref} \
	-o ${sampleID}_sv \
	--threads ${task.cpus}

	# rename vcf to show its from tiddit 
	mv ${sampleID}_sv.vcf \
		Tiddit_${sampleID}_sv.vcf
	"""
}

// rehead tiddit SV vcf for merging 
process rehead_tiddit {
	debug true 
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'
	container "${params.bcftools__container}"

	input:
	tuple val(sampleID), path(tiddit_vcf)
		
	output:
	path("Tiddit_*.vcf")	, emit: finalVCF
		
	script:
	"""
	# index smoove vcf 
	bgzip Tiddit_${sampleID}_sv.vcf
	tabix Tiddit_${sampleID}_sv.vcf.gz

	# create new header for merged vcf
	printf "${sampleID}_tiddit\n" > ${sampleID}_rehead_tiddit.txt

	# replace sampleID with caller_sample for merging 	
	bcftools reheader \
		Tiddit_${sampleID}_sv.vcf.gz \
		-s ${sampleID}_rehead_tiddit.txt \
		-o Tiddit_${sampleID}.vcf
	
	#clean up
	#rm -r ${sampleID}_rehead_tiddit.txt
	"""
}

// calculate coverage of bam files with tiddit cov
process tiddit_cov {
	debug true
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'

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