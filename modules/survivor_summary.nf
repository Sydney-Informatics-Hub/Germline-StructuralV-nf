// generate summary counts for merged VCF
process survivor_summary {
	tag "SAMPLE: ${params.sample}"
	debug false
	publishDir "${params.outDir}/${sample}/survivor", mode: 'copy'

	input:
	tuple val(sample), path(mergedVCF)

	output:
	tuple val(sample), path("*")
	
	script:
	"""
	SURVIVOR vcftobed ${sample}_merged.vcf \
		0 -1 \
		${sample}_merged.bed
	
	SURVIVOR stats ${sample}_merged.vcf \
		-1 -1 -1 \
		${sample}_merged.stats.txt
	"""

}

process survivor_venn {
	debug false
	publishDir "${params.outDir}/${sample}/survivor", mode: 'copy'

	input:
	tuple val(sample), path(mergedVCF)

	output:
	tuple val(sample), path("*")

	script:
	"""
	"""
}
