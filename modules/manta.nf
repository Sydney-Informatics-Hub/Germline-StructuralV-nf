#!/usr/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process manta {
	debug true
	publishDir "${params.outDir}/manta", mode: 'copy'

	// resource parameters. currently set to 4 CPUs
    cpus "${params.cpus}"

    // Run with container
	container "${params.manta__container}"
	
	input:
	 // matching the target bed with the sample tuple to parallelise sample runs across bed file
	tuple val(sampleID), file(bam), file(bai), file(mantaBED), file(mantaBED_tbi)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), file("*.vcf.gz")
	tuple val(sampleID), file("*.vcf.gz.tbi")
	//tuple val(sampleID), path("*candidateSmallIndels.vcf.gz")
	//tuple val(sampleID), path("*candidateSmallIndels.vcf.gz.tbi")
	//tuple val(sampleID), path("*candidate_sv.vcf.gz") 
	//tuple val(sampleID), path("*candidate_sv.vcf.gz.tbi") 
	//tuple val(sampleID), path("*diploid_sv.vcf.gz")
	//tuple val(sampleID), path("*diploid_sv.vcf.gz.tbi")

	script:
	// define custom function for optional use of target regions bed 
	def manta_bed = mantaBED ? "--callRegions $params.mantaBED" : ""
	
	"""
	# configure manta SV analysis workflow
	configManta.py \\
	--normalBam ${bam} \\
	--referenceFasta ${params.ref} \\
	--runDir manta \\
	$manta_bed 
	
	# run SV detection 
	manta/runWorkflow.py -m local -j ${params.cpus}
	
	# clean up outputs, put them all in one place 
	##mv manta/results/variants/candidateSmallIndels.vcf.gz \
    ##    Manta_${sampleID}.candidateSmallIndels.vcf.gz
    ##mv manta/results/variants/candidateSmallIndels.vcf.gz.tbi \
    ##    Manta_${sampleID}.candidateSmallIndels.vcf.gz.tbi
    ##mv manta/Manta/results/variants/candidateSV.vcf.gz \
    ##   	Manta_${sampleID}.candidateSV.vcf.gz
    ##mv manta/Manta/results/variants/candidateSV.vcf.gz.tbi \
    ##    Manta_${sampleID}.candidateSV.vcf.gz.tbi
    ##mv manta/Manta/results/variants/diploidSV.vcf.gz \
    ##    Manta_${sampleID}.diploidSV.vcf.gz
    ##mv manta/Manta/results/variants/diploidSV.vcf.gz.tbi \
    ##    Manta_${sampleID}.diploidSV.vcf.gz.tbi
	"""
} 
