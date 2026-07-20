// calculate coverage of bam files with tiddit cov
process tiddit_cov {
	debug false
	publishDir "${params.outDir}/${sampleID}/tiddit", mode: 'copy'
	container 'quay.io/biocontainers/tiddit:3.6.0--py310hc2b7f4b_0'
	
	input:
	tuple val(sampleID), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sampleID), path("*.bed")
	
	script:
	def extraArgs = params.extraTidditCovFlags ?: ''
	"""
	tiddit \
		--cov \
		--bam ${bam} \
		--ref ${params.ref} \
		-o ${sampleID}_cov  ${extraArgs}
	"""

}
