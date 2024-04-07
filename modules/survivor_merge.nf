// Merge manta, smoove, tiddit vcfs 
process survivor_merge {
	tag "SAMPLE: ${params.sample}"
	debug false
	publishDir "${params.outDir}/${sample}/survivor", mode: 'copy'
		
	input:
	//tuple val(sample), path(mergelist)
	tuple val(sample), path(mergeFile)

	output:
	tuple val(sample), path("${sample}_survivor.txt"), emit: mergeFile
	tuple val(sample), path("${sample}_merged.vcf"), emit: mergedVCF

	script:
	// for zero explainer see https://github.com/fritzsedlazeck/SURVIVOR/issues/162 
	"""
	echo ${mergeFile} | xargs -n1 > ${sample}_survivor.txt

	SURVIVOR merge ${sample}_survivor.txt \
		${params.survivorMaxDist} \
		${params.survivorConsensus} \
		${params.survivorType} \
		${params.survivorStrand} \
		0 \
		${params.survivorSize} \
		${sample}_merged.vcf
	"""
}
