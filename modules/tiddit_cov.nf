// calculate coverage of bam files with tiddit cov
process tiddit_cov {
	tag "SAMPLE: ${params.sample}"
	debug false
	publishDir "${params.outDir}/${sample}/tiddit", mode: 'copy'
	
	input:
	tuple val(sample), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sample), path("*.bed")
	
	script:
	def extraArgs = params.extraTidditCovFlags ?: ''
	"""
	tiddit \
		--cov \
		--bam ${bam} \
		--ref ${params.ref} \
		-o ${sample}_cov  ${extraArgs}
	"""

}
