// calculate coverage of bam files with tiddit cov
process tiddit_cov {
	debug false
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
	def extraArgs = params.extraTidditCovFlags ?: ''
	"""
	tiddit \
		--cov \
		--bam ${bam} \
		--ref ${params.ref} \
		-o ${sampleID}_cov  ${extraArgs}
	"""

}
