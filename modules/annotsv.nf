// run annotSV for variant annotation (human, mouse only)
process annotsv {
	debug false
	publishDir "${params.outDir}/${sampleID}/annotsv", mode: 'copy'
	container "${params.annotsv__container}"

	input:
	tuple val(sampleID), path(mergedVCF)
	path "${params.annotsvDir}"
	val annotsvType

	output:
	tuple val(sampleID), path("*")

	script: 
	def mode = "${params.annotsvMode}"
	"""
	AnnotSV \
		-SVinputFile ${sampleID}_merged.vcf \
		-annotationsDir ${params.annotsvDir} \
		-bedtools bedtools -bcftools bcftools \
		-annotationMode ${mode} \
		-genomeBuild GRCh38 \
		-includeCI 1 \
		-overwrite 1 \
		-outputFile ${sampleID}_AnnotSV.tsv
	"""
}
