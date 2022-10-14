#!/usr/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process manta {
	debug true
	// unlike other processes, manta makes its own workdir, no need to specify full outDir path for each sample
	publishDir "${params.outDir}/${sampleID}", mode: 'copy'

	// resource parameters. currently set to 4 CPUs
    cpus "${params.cpus}"

    // Run with container
	container "${params.mulled__container}"
	
	input:
	 // matching the target bed with the sample tuple to parallelise sample runs across bed file
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	path("manta/*.candidateSmallIndels.vcf.gz")    , emit: small_indels
    path("manta/*.candidateSmallIndels.vcf.gz.tbi"), emit: small_indels_tbi
    path("manta/*.candidateSV.vcf.gz")             , emit: candidate
    path("manta/*.candidateSV.vcf.gz.tbi")         , emit: candidate_tbi
    path("manta/*.diploidSV.vcf.gz")               , emit: diploid
    path("manta/*.diploidSV.vcf.gz.tbi")           , emit: diploid_tbi

	script:
	// define custom function for optional use of target regions bed 
	// TODO add optional use of bed file- will need to add $manta_bed to configManta.py code 
	//def manta_bed = mantaBED ? "--callRegions $params.mantaBED" : ""
	
	"""
	# configure manta SV analysis workflow
		configManta.py \\
		--normalBam ${bam} \\
		--referenceFasta ${params.ref} \\
		--runDir manta \\
	
	# run SV detection 
	manta/runWorkflow.py -m local -j ${params.cpus}

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
		
	rm -rf manta/results/variants
	"""
} 
