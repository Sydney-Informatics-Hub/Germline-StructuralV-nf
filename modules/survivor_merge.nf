// Merge manta, smoove, tiddit vcfs 
process survivor_merge {
	debug false
	publishDir "${params.outDir}/${sampleID}/survivor", mode: 'copy'
	container 'quay.io/biocontainers/survivor:1.0.7--hd03093a_2'
		
	input:
	//tuple val(sampleID), path(mergelist)
	tuple val(sampleID), path(mergeFile)

	output:
	tuple val(sampleID), path("${sampleID}_survivor.txt"), emit: mergeFile
	tuple val(sampleID), path("${sampleID}_merged.vcf"), emit: mergedVCF

	script:
	// for zero explainer see https://github.com/fritzsedlazeck/SURVIVOR/issues/162 
	"""
	echo ${mergeFile} | xargs -n1 > ${sampleID}_survivor.txt

	SURVIVOR merge ${sampleID}_survivor.txt \
		${params.survivorMaxDist} \
		${params.survivorConsensus} \
		${params.survivorType} \
		${params.survivorStrand} \
		0 \
		${params.survivorSize} \
		${sampleID}_merged.vcf
	"""
}
