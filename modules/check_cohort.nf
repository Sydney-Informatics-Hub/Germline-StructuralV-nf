#!/usr/bin/env nextflow

// Using DSL-2
nextflow.enable.dsl=2

process checkInputs {
	// no publishDir specified as no need to recreate samples.tsv 

	// Plan to write python script to check integrity of file
	// confirm tab separated, confirm correct number of columns
  
	input:
	path cohort

	output:
	file "samples.txt"
	
	script:
	"""
	cat "${params.cohort}" > samples.txt
	"""
  }
