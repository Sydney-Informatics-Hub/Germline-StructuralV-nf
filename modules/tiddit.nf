#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process survivor_merge {
	debug
	publishDir

	// resource parameters. currently set to 4 CPUs
        cpus "${params.cpus}"

        // Run with container
	container "${params.tiddit__container}"
	
	input:
	
	output:

	script:
	"""
	"""
} 
