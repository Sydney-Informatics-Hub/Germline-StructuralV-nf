#!/usr/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process manta {
	debug true
	// manta makes its out outdir
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'

    // Run with container
	container "${params.mulled__container}"
	
	input:
	 // matching the target bed with the sample tuple to parallelise sample runs across bed file
	tuple val(sampleID), file(bam), file(bai)
	//file(mantaBED)
	//file(mantaBED_tbi)
	path(ref)
	path(ref_fai)

	output:
	path("manta/*.candidateSmallIndels.vcf.gz")    	, emit: manta_small_indels
    path("manta/*.candidateSmallIndels.vcf.gz.tbi")	, emit: manta_small_indels_tbi
    path("manta/*.candidateSV.vcf.gz")             	, emit: manta_candidate
    path("manta/*.candidateSV.vcf.gz.tbi")         	, emit: manta_candidate_tbi
    path("manta/*.diploidSV.vcf.gz")               	, emit: manta_diploid
    path("manta/*.diploidSV.vcf.gz.tbi")           	, emit: manta_diploid_tbi
	path("manta/*.diploid_converted.vcf")			, emit: manta_diploid_converted
	path("manta/*.diploid_converted.vcf.gz.tbi")	, emit: manta_diploid_converted_tbi
	path("MantaVCF_path")							, emit: manta_VCF

	script:
	// define custom functions for optional flags
	//def manta_bed = mantaBED ? "--callRegions $params.mantaBED" : ""
	// TODO: add optional parameters. 
	"""
	# configure manta SV analysis workflow
		configManta.py \
		--normalBam ${bam} \
		--referenceFasta ${params.ref} \
		--runDir manta \

	# run SV detection 
	manta/runWorkflow.py -m local -j 8

	# convert multiline inversion BNDs from manta vcf to single line
	convertInversion.py \$(which samtools) ${params.ref} manta/results/variants/diploidSV.vcf.gz \
		| bgzip --threads ${params.cpus} > manta/results/variants/diploid_converted.vcf.gz
    
	# index vcf
	tabix manta/results/variants/diploid_converted.vcf.gz

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
	mv manta/results/variants/diploid_converted.vcf.gz \
		manta/Manta_${sampleID}.diploid_converted.vcf.gz
	mv manta/results/variants/diploid_converted.vcf.gz.tbi \
		manta/Manta_${sampleID}.diploid_converted.vcf.gz.tbi

	gunzip manta/Manta_${sampleID}.diploid_converted.vcf.gz

	#collect file name for merging 
	echo manta/Manta_${sampleID}.diploidSV_converted.vcf > MantaVCF_path 
	"""
} 
