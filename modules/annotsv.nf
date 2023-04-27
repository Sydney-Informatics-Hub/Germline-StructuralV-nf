// run annotSV for variant annotation (human, mouse only)
process annotsv {
	debug false
	publishDir "${params.outDir}/${sampleID}/annotsv", mode: 'copy'
	container "${params.annotsv__container}"

	input:
	tuple val(sampleID), path(mergedVCF)
	path annotsvDir
	val annotsvMode

	output:
	tuple val(sampleID), path("*_AnnotSV")

	script: 
	// Apply annotation mode flag to command
	def mode = params.annotsvMode
	
	// Change output file name based on annotation mode
	def outputFile = null
	    if (mode == 'full') {
               outputFile = "${sampleID}_full_AnnotSV.tsv"
            } else if (mode == 'split') {
               outputFile = "${sampleID}_split_AnnotSV.tsv"
            } else if (mode == 'both') {
               outputFile = "${sampleID}_both_AnnotSV.tsv"
            } else {
               throw new RuntimeException("Invalid option for --annotSV: ${mode}")}
	
	//Pass any additional flags to the AnnotSV 
	def extraArgs = params.extraAnnotsvFlags ?: ''
	"""
	AnnotSV \
		-SVinputFile ${sampleID}_merged.vcf \
		-annotationsDir ${params.annotsvDir} \
		-bedtools bedtools -bcftools bcftools \
		-annotationMode ${mode} \
		-genomeBuild GRCh38 \
		-includeCI 1 \
		-overwrite 1 \
		-outputFile ${outputFile} ${extraArgs}
	"""
}
