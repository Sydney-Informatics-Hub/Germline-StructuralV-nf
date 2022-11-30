#!/usr/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// run manta structural variant detection and convert inversions
process manta {
	debug false
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'
	container "${params.mulled__container}"

	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("manta/Manta_${sampleID}.candidateSmallIndels.vcf.gz")	, emit: manta_small_indels
	tuple val(sampleID), path("manta/Manta_${sampleID}.candidateSmallIndels.vcf.gz.tbi")	, emit: manta_small_indels_tbi
	tuple val(sampleID), path("manta/Manta_${sampleID}.candidateSV.vcf.gz")			, emit: manta_candidate
	tuple val(sampleID), path("manta/Manta_${sampleID}.candidateSV.vcf.gz.tbi")		, emit: manta_candidate_tbi
	tuple val(sampleID), path("manta/Manta_${sampleID}.diploidSV.vcf.gz")			, emit: manta_diploid
	tuple val(sampleID), path("manta/Manta_${sampleID}.diploidSV.vcf.gz.tbi")		, emit: manta_diploid_tbi
	tuple val(sampleID), path("manta/Manta_${sampleID}.diploidSV_converted.vcf.gz")		, emit: manta_diploid_convert
	tuple val(sampleID), path("manta/Manta_${sampleID}.diploidSV_converted.vcf.gz.tbi")	, emit: manta_diploid_convert_tbi

	script:
	// TODO: add optional parameters. 
	// define custom functions for optional flags
	//def intervals = intervals ? "--callRegions $params.intervals" : ""
	"""
	# configure manta SV analysis workflow
		configManta.py \
		--normalBam ${bam} \
		--referenceFasta ${params.ref} \
		--runDir manta 

	# run SV detection 
	manta/runWorkflow.py -m local -j ${task.cpus}

	# clean up outputs
	mv manta/results/variants/candidateSmallIndels.vcf.gz \
		manta/Manta_${sampleID}.candidateSmallIndels.vcf.gz
	mv manta/results/variants/candidateSmallIndels.vcf.gz.tbi \
		manta/Manta_${sampleID}.candidateSmallIndels.vcf.gz.tbi
	mv manta/results/variants/candidateSV.vcf.gz \
		manta/Manta_${sampleID}.candidateSV.vcf.gz
	mv manta/results/variants/candidateSV.vcf.gz.tbi \
		manta/Manta_${sampleID}.candidateSV.vcf.gz.tbi
	mv manta/results/variants/diploidSV.vcf.gz \
		manta/Manta_${sampleID}.diploidSV.vcf.gz
	mv manta/results/variants/diploidSV.vcf.gz.tbi \
		manta/Manta_${sampleID}.diploidSV.vcf.gz.tbi
	
	# convert multiline inversion BNDs from manta vcf to single line
	convertInversion.py \$(which samtools) ${params.ref} \
		manta/Manta_${sampleID}.diploidSV.vcf.gz \
		> manta/Manta_${sampleID}.diploidSV_converted.vcf

	# zip and index converted vcf
	bgzip manta/Manta_${sampleID}.diploidSV_converted.vcf
	tabix manta/Manta_${sampleID}.diploidSV_converted.vcf.gz
	"""
} 

// rehead manta SV vcf for merging 
process rehead_manta {
	debug false 
	publishDir "${params.outDir}/${sampleID}/manta", mode: 'copy'
	container "${params.bcftools__container}"

	input:
	tuple val(sampleID), path(manta_diploid_convert)
	tuple val(sampleID), path(manta_diploid_convert_tbi)

	output:
	tuple val(sampleID), path("Manta_*.vcf")	, emit: manta_VCF
		
	script:
	"""
	# create new header for merged vcf
	printf "${sampleID}_manta\n" > ${sampleID}_rehead_manta.txt

	# replace sampleID with caller_sample for merging
	bcftools reheader \
		Manta_${sampleID}.diploidSV_converted.vcf.gz \
		-s ${sampleID}_rehead_manta.txt \
		-o Manta_${sampleID}.vcf.gz

	# gunzip vcf
	gunzip Manta_${sampleID}.vcf.gz
	"""
}
