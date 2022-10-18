#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Import subworkflows to be run in the workflow
include { checkInputs }     from './modules/check_cohort'
include { smoove }          from './modules/smoove' 
//include { rehead_smoove } from './modules/smoove'
include { manta }           from './modules/manta'
include { rehead_manta }    from './modules/manta'
//include { tiddit_sv }       from './modules/tiddit'
//include { rehead_tiddit } from './modules/tiddit'
//include { tiddit_cov }      from './modules/tiddit'
//include { survivor_merge }  from './modules/survivor'


// Print the header to screen when running the pipeline
log.info """\

        =================================================
        =================================================
          G E R M L I N E  S T R U C T U R A L  V - N F 
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

 Documentation @ https://github.com/Sydney-Informatics-Hub/Germline-StructuralV-nf

 Cite this pipeline @ TODO:INSERT DOI

 Log issues @ https://github.com/Sydney-Informatics-Hub/Germline-StructuralV-nf/issues

 All of the default parameters are set in `nextflow.config`

=======================================================================================
Workflow run parameters 
=======================================================================================

input       : ${params.input}
reference   : ${params.ref}
outDir      : ${params.outDir}
workDir     : ${workflow.workDir}

=======================================================================================

 """

// Help function 
// This help function will be run if essential part of run command is incorrect/missing 
// TODO: once finalised, add all optional and required flags in

def helpMessage() {
    log.info"""
  Usage:  nextflow run main.nf --input samplesheet.tsv --ref reference.fasta

  Required Arguments:

	--input		Full path and name of sample input file (tsv format).

	--ref			Full path and name of reference genome (fasta format).

    """.stripIndent()
}

/// Main workflow structure. 
workflow {

// Show help message if --help is run or if any required params are not 
// provided at runtime

    if ( params.help == true || params.ref == false || params.input == false ){
        // Invoke the help function above and exit
              helpMessage()
              exit 1

        // consider adding some extra contigencies here.
        // could validate path of all input files in list?
        // could validate indexes for input files exist?
        // could validate indexes for reference exist?
        // confirm with each tool, any requirements for their run?

	} else {
	
	// Check inputs file exists
	checkInputs(Channel.fromPath(params.input, checkIfExists: true))
	
	// Split cohort file to collect info for each sample
  input = checkInputs.out
          .splitCsv(header: true, sep:"\t")
          .map { row -> tuple(row.sampleID, file(row.bam), file(row.bai))}
 
	// Call SVs with Manta  
	//manta(input, params.mantaBED, params.mantaBED_tbi, params.ref, params.ref+'.fai')
  manta(input, params.ref, params.ref+'.fai')
	
  // Rehead manta file for merging 
  rehead_manta(input, manta.out.manta_diploid_convert, manta.out.manta_diploid_convert_tbi, params.ref, params.ref+'.fai')

  // Call SVs with Smoove
	//smoove(input, params.ref, params.ref+'.fai')

	// Run TIDDIT sv
	//tiddit_sv(input, params.ref, params.ref+'.fai')

	// Run TIDDIT cov 
	//tiddit_cov(input, params.ref, params.ref+'.fai')

  // Collect VCFs for merging
  //mergelist = tiddit_sv.out.tiddit_VCF.concat(smoove.out.smoove_VCF, manta.out.manta_VCF)
  //        .groupTuple()
  //        .collectFile(name: "${params.outDir}/${sampleID}/sampleVCFs.txt", sort: false)
  //
  // Run SURVIVOR merge
  //survivor_merge(input, mergelist)
  // Run SURVIVOR vcf2bedpe
}}

workflow.onComplete {
  summary = """
=======================================================================================
Workflow execution summary
=======================================================================================

Duration    : ${workflow.duration}
Success     : ${workflow.success}
workDir     : ${workflow.workDir}
Exit status : ${workflow.exitStatus}
outDir      : ${params.outDir}

=======================================================================================
  """

  println summary

}
