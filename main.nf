#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Import subworkflows to be run in the workflow
include { checkInputs     }   from './modules/check_cohort'
include { smoove          }   from './modules/smoove' 
include { rehead_smoove   }   from './modules/smoove'
include { manta           }   from './modules/manta'
include { rehead_manta    }   from './modules/manta'
include { tiddit_sv       }   from './modules/tiddit'
include { rehead_tiddit   }   from './modules/tiddit'
include { tiddit_cov      }   from './modules/tiddit'
include { survivor_merge  }   from './modules/survivor'
include { survivor_bed    }   from './modules/survivor'
//include { VEPgtf_prep     }   from './modules/prep_gtf'
//include { VEPgtf_run      }   from './modules/ensemblVEP'
//include { VEPcache_prep  }   from './modules/ensemblVEP'
include { VEPcache_run    }   from './modules/ensemblVEP'

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

	--input		  Full path and name of sample input file (tsv format).

	--ref			  Full path and name of reference genome (fasta format).

  Optional Arguments:

  --outDir    Specify name of results directory. 

  --gtf       Path to GTF file for transcript annotations with VEP. This
              will run VEP offline, rather than with cache (.gz format). 

  --VEPcache  Path to prepared VEP cache directory. This will run VEP using
              downloaded and prepared cache.   

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
  manta(input, params.ref, params.ref+'.fai')

  // Rehead manta vcf for merging 
  // TODO concat all reheading processes, run across samples x callers
  rehead_manta(manta.out.manta_diploid_convert, manta.out.manta_diploid_convert_tbi)

  // Call SVs with Smoove
	smoove(input, params.ref, params.ref+'.fai')

  // Rehead smoove vcf for merging  
  // TODO concat all reheading processes, run across samples x callers
  rehead_smoove(smoove.out.smoove_geno)

	// Run TIDDIT sv
	tiddit_sv(input, params.ref, params.ref+'.fai')
  
  // Rehead TIDDIT vcf for merging
  // TODO concat all reheading processes, run across samples x callers
  rehead_tiddit(tiddit_sv.out.tiddit_vcf)

	// Run TIDDIT cov 
	tiddit_cov(input, params.ref, params.ref+'.fai')

  // Collect VCFs for merging
 mergeFile = rehead_tiddit.out.tiddit_VCF
              .concat(rehead_smoove.out.smoove_VCF, rehead_manta.out.manta_VCF)
              .groupTuple() 

  // Run SURVIVOR merge
  survivor_merge(mergeFile)

  // Run SURVIVOR vcf2bedpe
  survivor_bed(survivor_merge.out.mergedVCF)

  // Run Ensembl's VEP for variant annotation 
  // TODO see #10 (https://github.com/Sydney-Informatics-Hub/Germline-StructuralV-nf/issues/10)
  
  // If --VEPcache flag, then download cache directory
  if (params.VEPcache) {
    // download cache dir
    // TODO test this, currently required pre-downloaded cache 
    // VEPcache_prep()
    // run vep with cache
    VEPcache_run(survivor_merge.out.mergedVCF, params.VEPcache)
  }
    // TODO once vep_cache_prep() is running change to 
    //vep_cache_run(survivor_merge.out.mergedVCF, VEPcache_prep.out.cacheVEP, params.ref)
    
  // If --gtf prepare gtf and then run transcript level annotations only
  //if (params.gtf) {
  //  VEPgtf_prep(params.gtf)
  //  VEPgtf_run(survivor_merge.out.mergedVCF, 
  //              params.ref, 
  //              VEPgtf_prep.out.VEPgtf_gz, 
  //              VEPgtf_prep.out.VEPgtf_tbi,
  //              params.VEPcache)
// }
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
