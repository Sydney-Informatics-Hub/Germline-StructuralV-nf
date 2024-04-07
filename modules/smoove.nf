// run smoove structural variant detection
process smoove {
	debug false
	publishDir "${params.outDir}/${sample}", mode: 'copy'

	input:
	tuple val(sample), file(bam), file(bai)
	path(ref)
	path(ref_fai)

	output:
	tuple val(sample), path("smoove/${sample}-smoove.genotyped.vcf.gz")		, emit: smoove_geno
	tuple val(sample), path("smoove/${sample}-smoove.genotyped.vcf.gz.csi")	, emit: smoove_geno_csi
	tuple val(sample), path("smoove/${sample}.split.bam")			, emit: smoove_split, optional: true
	tuple val(sample), path("smoove/${sample}.split.bam.csi")			, emit: smoove_split_csi, optional: true
	tuple val(sample), path("smoove/${sample}.disc.bam")			, emit: smoove_disc, optional: true
	tuple val(sample), path("smoove/${sample}.disc.bam.csi")			, emit: smoove_disc_csi, optional: true
	tuple val(sample), path("smoove/${sample}.histo")				, emit: smoove_histo, optional: true
	
	script:
	def extraArgs = params.extraSmooveFlags ?: ''
	"""
	smoove call -d --name ${sample} \
		--fasta ${params.ref} \
		--outdir smoove \
		--processes ${task.cpus} \
		--genotype ${bam} ${extraArgs}
	"""
} 

// rehead smoove genotyped vcf for merging 
process rehead_smoove {
	debug false 
	publishDir "${params.outDir}/${sample}/smoove", mode: 'copy'

	input:
	tuple val(sample), path(smoove_geno)
		
	output:
	tuple val(sample), path("Smoove_${sample}.vcf")	, emit: smoove_VCF	
		
	script:
	"""
	# create new header for merged vcf
	printf "${sample}_smoove\n" > ${sample}_rehead_smoove.txt

	# replace sample with caller_sample for merging 	
	bcftools reheader \
		${sample}-smoove.genotyped.vcf.gz \
		-s ${sample}_rehead_smoove.txt \
		-o Smoove_${sample}.vcf.gz
	
	# gunzip vcf
	gunzip Smoove_${sample}.vcf.gz
	
	#clean up
	#rm -r ${sample}_rehead_smoove.txt
	"""
}
