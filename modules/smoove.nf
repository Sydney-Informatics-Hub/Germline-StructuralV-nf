#!/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process smoove {
	debug
	publishDir

	// resource parameters
        cpus "${params.cpus}"

        // Run with container
	container "${params.smoove__container}"
	
	input:
	
	output:

	script:
	"""
	"""
} 
