#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// run tiddit structural variant detection
process tiddit_sv {
	debug true
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'

    // Run with container
	container "${params.tiddit__container}"
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	path("Tiddit_${sampleID}_sv.vcf") 	, emit: tiddit_vcf
	path("${sampleID}_sv.ploidies.tab") , emit: tiddit_ploidy
	path("${sampleID}_sv_tiddit") 		, emit: tiddit_workdir
	
	script:
	// will need to add option for additional flags. See manta script for example
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

process rehead_tiddit {
	debug true 
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'
	container "${params.bcftools__container}"

	input:
	//TODO: work out how pass input without associating a bam to the sampleID?
	tuple val(sampleID), path("")
	path(tiddit_vcf)
		
	output:
	path("Tiddit_${sampleID}.vcf")	, emit: Tiddit_finalVCF	
		
	script:
	"""
	# index smoove vcf 
	bgzip tiddit/Tiddit_${sampleID}_sv.vcf
	tabix tiddit/Tiddit_${sampleID}_sv.vcf.gz

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

// calculate coverage of bam files 
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