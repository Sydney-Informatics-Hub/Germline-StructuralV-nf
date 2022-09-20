#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Import subworkflows to be run in the workflow
include { checkInputs } from './modules/check_cohort'
include { smoove } from './modules/smoove' 
include { tiddit_sv } from './modules/tiddit'
include { tiddit_cov } from './modules/tiddit'
//include { manta } from './modules/manta'

// Print the header to screen when running the pipeline
log.info """\

        =================================================
        =================================================
          G E R M L I N E  S T R U C T U R A L  V - n f  
        =================================================
        =================================================

    -._    _.--'"`'--._    _.--'"`'--._    _.--'"`'--._    _  
       '-:`.'|`|"':-.  '-:`.'|`|"':-.  '-:`.'|`|"':-.  '.` :    
     '.  '.  | |  | |'.  '.  | |  | |'.  '.  | |  | |'.  '.:    
     : '.  '.| |  | |  '.  '.| |  | |  '.  '.| |  | |  '.  '.  
     '   '.  `.:_ | :_.' '.  `.:_ | :_.' '.  `.:_ | :_.' '.  `.  
            `-..,..-'       `-..,..-'       `-..,..-'       `       


                      ~~~~ Version: 1.0 ~~~~
 

 Created by the Sydney Informatics Hub, University of Sydney

 Find documentation and more info @ https://github.com/Sydney-Informatics-Hub/Germline-StructuralV-nf

 Cite this pipeline @ INSERT DOI

 Log issues @ https://github.com/Sydney-Informatics-Hub/Germline-StructuralV-nf/issues

 All of the default parameters are set in `nextflow.config`
 """

// Help function 
// This help function will be run if essential part of run command is incorrect/missing 

def helpMessage() {
    log.info"""
  Usage:  nextflow run main.nf --cohort --ref 

  Required Arguments:

	--cohort		Full path and name of sample input file (tab separated).

	--ref			  Full path and name of reference genome (.fasta format).

    """.stripIndent()
}

/// Main workflow structure. Include some input/runtime tests here.

workflow {

// Show help message if --help is run or if any required params are not 
// provided at runtime

        if ( params.help == true || params.ref == false || params.cohort == false ){
        // Invoke the help function above and exit
              helpMessage()
              exit 1

        // consider adding some extra contigencies here.
        // could validate path of all input files in list?
        // could validate indexes for input files exist?
        // could validate indexes for reference exist?
        // confirm with each tool, any requirements for their run?

// if none of the above are a problem, then run the workflow
	} else {
	
	// Check inputs
	checkInputs(Channel.fromPath(params.cohort, checkIfExists: true))
	
	// Split cohort file to collect info for each sample
        cohort = checkInputs.out
                        .splitCsv(header: true, sep:"\t")
                        .map { row -> tuple(row.sampleID, file(row.bam), file(row.bai))}

	// Manta  
	//manta(cohort, params.ref, params.ref+'.fai')

	// Smoove
	smoove(cohort, params.ref, params.ref+'.fai')

	// TIDDIT sv
	tiddit_sv(cohort, params.ref, params.ref+'.fai')

  // TIDDIT cov 
  tiddit_cov(cohort, params.ref, params.ref+'.fai')

	// Survivor 
	//survivor(cohort)	
}}

workflow.onComplete {
	log.info ( workflow.success ? "\nDone! Outputs are in `${params.outDir}`" : "Oops .. something went wrong" )
}
