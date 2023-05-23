// generate summary counts for merged VCF
process survivor_summary {
	debug false
	publishDir "${params.outDir}/${sampleID}/survivor", mode: 'copy'

	input:
	tuple val(sampleID), path(mergedVCF)

	output:
	tuple val(sampleID), path("*")
	
	script:
	"""
	SURVIVOR vcftobed ${sampleID}_merged.vcf \
		0 -1 \
		${sampleID}_merged.bed
	
	SURVIVOR stats ${sampleID}_merged.vcf \
		-1 -1 -1 \
		${sampleID}_merged.stats.txt
	"""

}

process survivor_venn {
	debug false
	publishDir "${params.outDir}/${sampleID}/survivor", mode: 'copy'

	input:
	tuple val(sampleID), path(mergedVCF)

	output:
	tuple val(sampleID), path("*")

	script:
	"""
	"""
}
