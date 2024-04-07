// run tiddit structural variant detection
process tiddit_sv {
	tag "SAMPLE: ${params.sample}"
	debug false
	publishDir "${params.outDir}/${sample}/tiddit", mode: 'copy'

	input:
	tuple val(sample), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sample), path("Tiddit_${sample}_PASSsv.vcf")	, emit: tiddit_vcf
	tuple val(sample), path("${sample}_sv.ploidies.tab")	, emit: tiddit_ploidy
	tuple val(sample), path("${sample}_sv_tiddit")		, emit: tiddit_workdir
	
	script:
	def extraArgs = params.extraTidditSvFlags ?: ''
	"""
	tiddit \
		--sv \
		-q 20 \
		--bam ${bam} \
		--ref ${params.ref} \
		-o ${sample}_sv \
		--threads ${task.cpus} ${extraArgs}

	# rename vcf to show its from tiddit 
	mv ${sample}_sv.vcf \
		Tiddit_${sample}_sv.vcf

	# filter to pass only variants 
	grep -E "#|PASS" Tiddit_${sample}_sv.vcf \
		> Tiddit_${sample}_PASSsv.vcf
	"""
}

// rehead tiddit SV vcf for merging 
process rehead_tiddit {
	tag "SAMPLE: ${params.sample}"
	debug false 
	publishDir "${params.outDir}/${sample}/tiddit", mode: 'copy'
	container "${params.bcftools__container}"

	input:
	tuple val(sample), path(tiddit_vcf)
		
	output:
	tuple val(sample), path("Tiddit_${sample}_final.vcf")	, emit: tiddit_VCF
		
	script:
	"""
	# bgzip and index tiddit vcf 
	bgzip Tiddit_${sample}_PASSsv.vcf
	tabix Tiddit_${sample}_PASSsv.vcf.gz

	# create new header for merged vcf
	printf "${sample}_tiddit\n" > ${sample}_rehead_tiddit.txt

	# replace sample with caller_sample for merging 	
	bcftools reheader \
		Tiddit_${sample}_PASSsv.vcf.gz \
		-s ${sample}_rehead_tiddit.txt \
		-o Tiddit_${sample}_final.vcf.gz
	
	# gunzip vcf
	gunzip Tiddit_${sample}_final.vcf.gz
	
	#clean up
	rm -r ${sample}_rehead_tiddit.txt
	"""
}
