#!/usr/bin/env nextflow

// Enable DSL-2 syntax
nextflow.enable.dsl=2

// Define the process
process prepMerge {
	debug true
	publishDir "${params.outDir}/${sampleID}/survivor", mode: 'copy'

    // Run with container
	container "${params.mulled__container}"

    