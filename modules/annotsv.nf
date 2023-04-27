// run smoove structural variant detection
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
	def type = "${params.annotsvType}"
	"""
	AnnotSV \
		-SVinputFile ${sampleID}_merged.vcf \
		-annotationsDir ${params.annotsvDir} \
		-bedtools bedtools -bcftools bcftools \
		-annotationMode ${type} \
		-genomeBuild GRCh38 \
		-includeCI 1 \
		-overwrite 1 \
		-outputFile ${sampleID}_AnnotSV.tsv
	"""
}
