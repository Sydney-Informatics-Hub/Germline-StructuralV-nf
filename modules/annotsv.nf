// run smoove structural variant detection
process annotsv {
	debug false
	publishDir "${params.outDir}/${sampleID}/annotsv", mode: 'copy'
	container "${params.annotsv__container}"

	input:
	tuple val(sampleID), path(mergedVCF)
    path("${params.annotsvDir}")

	output:
	tuple val(sampleID), path("*_AnnotSV")

	script:
	// TODO: add optional parameters $args. 
	"""
    AnnotSV \
        -SVinputFile ${sampleID}_merged.vcf \
        -annotationsDir ${params.annotsvDir} \
        -bedtools bedtools -bcftools bcftools \
        -annotationMode full \
        -genomeBuild GRCh38 \
        -includeCI 1 \
        -overwrite 1 \
        -outputFile ${sampleID}_AnnotSV.tsv
	"""
}