// run manta structural variant detection and convert inversions
process manta {
	tag "SAMPLE: ${params.sample}"
	debug false
	publishDir "${params.outDir}/${sample}", mode: 'copy'

	input:
	tuple val(sample), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sample), path("manta/Manta_${sample}.candidateSmallIndels.vcf.gz")		, emit: manta_small_indels
	tuple val(sample), path("manta/Manta_${sample}.candidateSmallIndels.vcf.gz.tbi")	, emit: manta_small_indels_tbi
	tuple val(sample), path("manta/Manta_${sample}.candidateSV.vcf.gz")					, emit: manta_candidate
	tuple val(sample), path("manta/Manta_${sample}.candidateSV.vcf.gz.tbi")				, emit: manta_candidate_tbi
	tuple val(sample), path("manta/Manta_${sample}.diploidSV.vcf.gz")					, emit: manta_diploid
	tuple val(sample), path("manta/Manta_${sample}.diploidSV.vcf.gz.tbi")				, emit: manta_diploid_tbi
	tuple val(sample), path("manta/Manta_${sample}.diploidSV_converted.vcf.gz")			, emit: manta_diploid_convert
	tuple val(sample), path("manta/Manta_${sample}.diploidSV_converted.vcf.gz.tbi")		, emit: manta_diploid_convert_tbi

	script:
	def extraArgs = params.extraMantaFlags ?: ''
	def intervals = params.intervals ? "--callRegions $params.intervals" : ''
	"""
	# configure manta SV analysis workflow
	configManta.py \
		--normalBam ${bam} \
		--referenceFasta ${params.ref} \
		--runDir manta \
		${intervals} ${extraArgs}

	# run SV detection 
	manta/runWorkflow.py -m local -j ${task.cpus}

	# clean up outputs
	mv manta/results/variants/candidateSmallIndels.vcf.gz \
		manta/Manta_${sample}.candidateSmallIndels.vcf.gz
	mv manta/results/variants/candidateSmallIndels.vcf.gz.tbi \
		manta/Manta_${sample}.candidateSmallIndels.vcf.gz.tbi
	mv manta/results/variants/candidateSV.vcf.gz \
		manta/Manta_${sample}.candidateSV.vcf.gz
	mv manta/results/variants/candidateSV.vcf.gz.tbi \
		manta/Manta_${sample}.candidateSV.vcf.gz.tbi
	mv manta/results/variants/diploidSV.vcf.gz \
		manta/Manta_${sample}.diploidSV.vcf.gz
	mv manta/results/variants/diploidSV.vcf.gz.tbi \
		manta/Manta_${sample}.diploidSV.vcf.gz.tbi
	
	# convert multiline inversion BNDs from manta vcf to single line
	convertInversion.py \$(which samtools) ${params.ref} \
		manta/Manta_${sample}.diploidSV.vcf.gz \
		> manta/Manta_${sample}.diploidSV_converted.vcf

	# zip and index converted vcf
	bgzip manta/Manta_${sample}.diploidSV_converted.vcf
	tabix manta/Manta_${sample}.diploidSV_converted.vcf.gz
	"""
} 

// rehead manta SV vcf for merging 
process rehead_manta {
	tag "SAMPLE: ${params.sample}"
	debug false 
	publishDir "${params.outDir}/${sample}/manta", mode: 'copy'

	input:
	tuple val(sample), path(manta_diploid_convert)
	tuple val(sample), path(manta_diploid_convert_tbi)

	output:
	tuple val(sample), path("Manta_*.vcf")	, emit: manta_VCF
		
	script:
	"""
	# create new header for merged vcf
	printf "${sample}_manta\n" > ${sample}_rehead_manta.txt

	# replace sample with caller_sample for merging
	bcftools reheader \
		Manta_${sample}.diploidSV_converted.vcf.gz \
		-s ${sample}_rehead_manta.txt \
		-o Manta_${sample}.vcf.gz

	# gunzip vcf
	gunzip Manta_${sample}.vcf.gz
	"""
}
