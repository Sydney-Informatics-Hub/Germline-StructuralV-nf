# PIPE-3042 pipeline development notes
#### Georgie Samaha

## pipeline design
- multiple SV callers: manta, smoove, tiddit  
- merge SV vcfs with survivor = 1x final SV vcf /sample 
- genome-wide read depth with tiddit cov 
- output final vcf and bed file for easy interpretation
- VEP for variant annotation
- Consider generating html report / sample 

## design and testing 
- all SV callers previously tested 
- nextflow considerations:
- vcfs will need to be reheaded for input to survivor (so know which caller it came from)

### Manta 
- issues with feeding in the targeted regions bed file index 
- [Issue #92](https://github.com/Illumina/manta/issues/92) for Manta 
- potential issue with using a subset bam?
- checked bam and fasta chr/contig lists 
	- fasta has alt, decoy, unplaced scaffolds
	- bams have primary assembly only
- ameliorate by using bed file to specify regions to work with?
	- specify manta bed.gz and manta bed.tbi: issue persisted
	- reducing reference fasta to input: with ~/ALS_scripts/extractFasta.pl W0RKED
- able to run config step, then get error: Unhandled Exception in TaskRunner-Thread-masterWorkflow
	- [this issue](https://github.com/bcbio/bcbio-nextgen/issues/1308) implies its a problem with read/write to working directory 
	- tested with bash script, issue persists (not a nextflow problem)
	- Unable to resolve, lodged [issue](https://github.com/Illumina/manta/issues/295) at Manta GitHub. 
- SB mentioned she was able to run with test data, suggested I reformat nimbus and rerun. Did not need to do this. 
	- Fixed pyflow issue, was issue with --callregions bedfile containing regions not in subset bam 
- added additional process for inversions with convertinversions.py
    - Inversions FYI in [documentation](https://github.com/Illumina/manta/blob/75b5c38d4fcd2f6961197b28a41eb61856f2d976/docs/userGuide/README.md#inversions)
- TODO additional flags specification 

### Tiddit 
- running tiddit sv mode and cov mode 
- tiddit needs fasta bwa indexes  
- both sv and cov modules written. tiddit multi-threads
    - provided task.cpus = 10 but both tiddit sv and cov only used 4? 
- TODO output plot of coverage .bed?
- scripts external to modules will need to be stored in ./modules/Scripts/.
- Tiddit VCF needs filtering to PASS only variants, and quality threshold
- tiddit v 3.0.0 got rid of QUAL field, working on replacing it.. https://github.com/SciLifeLab/TIDDIT/issues/96

### Smoove
- test script works fine /home/ubuntu/Germline-StructuralV-nf/testScripts/smoove_test.sh 
- nextflow works, consider adding stats tool to summarise output to code block 
- was not outputting all files with subset data. Some output files are optional, depending on results. Have specified this in nextflow with `optional: true` in input section 

### SURVIVOR
- processes: merge, vcftobed, stats
- all vcfs need reheading before merging with survivor 
- survivor does not accept .gz vcfs, needed to gunzip manta, smoove 
- written stats process
- TODO write venn diagram comparison process to find overlap with callers. 

## pipeline presentation 
- stopped processes from printing stdout to screen with `debug: false`
- TODO: print pipeline summary to screen 
- TODO: nimbus config
- TODO: write report process. Use R container, probably need to make a custom container.

## report 
- See [here]*(https://stackoverflow.com/questions/21512918/how-to-use-knitr-from-command-line-with-rscript-and-command-line-argument) for generating Rmd with Rscript.
	- Rscript -e "library(knitr); stitch('my_code.R')" --args foo bar whatever=blabla 
## things to add to documentation 
- specify need for manta bam and reference consistency

## TODO future development 
- benchmark tiddit, very slow ~11-14 hours for 30x human WGS
- NCI Gadi config file 
- Nimbus config file TO USE CVMFS, not preinstalled? Should we use sHPC instead? 
