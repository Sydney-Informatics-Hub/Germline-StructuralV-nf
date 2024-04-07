// run annotSV for variant annotation (human, mouse only)
process annotsv {
	tag "ANNOTATIONS: ${params.annotSV}" 
	debug false
	publishDir "${params.outDir}/${sample}/annotsv", mode: 'copy'

	input:
	tuple val(sample), path(mergedVCF)
	path annotsvDir
	val annotsvMode

	output:
	tuple val(sample), path("*_AnnotSV")

	script: 
	// Apply annotation mode flag to command
	def mode = params.annotsvMode
	
	// Change output file name based on annotation mode
	def outputFile = null
	    if (mode == 'full') {
               outputFile = "${sample}_full_AnnotSV.tsv"
            } else if (mode == 'split') {
               outputFile = "${sample}_split_AnnotSV.tsv"
            } else if (mode == 'both') {
               outputFile = "${sample}_both_AnnotSV.tsv"
            } else {
               throw new RuntimeException("Invalid option for --annotSV: ${mode}")}
	
	//Pass any additional flags to the AnnotSV 
	def extraArgs = params.extraAnnotsvFlags ?: ''
	"""
	AnnotSV \
		-SVinputFile ${sample}_merged.vcf \
		-annotationsDir ${params.annotsvDir} \
		-bedtools bedtools -bcftools bcftools \
		-annotationMode ${mode} \
		-genomeBuild GRCh38 \
		-includeCI 1 \
		-overwrite 1 \
		-outputFile ${outputFile} ${extraArgs}
	"""
}
