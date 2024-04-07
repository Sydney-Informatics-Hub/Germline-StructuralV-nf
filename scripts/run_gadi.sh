#!/bin/bash

#PBS -P 
#PBS -N 
#PBS -l walltime=10:00:00
#PBS -l ncpus=1
#PBS -l mem=80GB
#PBS -W umask=022
#PBS -q copyq
#PBS -e germlineStructuralV-nf.e
#PBS -o germlineStructuralV-nf.o
#PBS -l wd
#PBS -l storage=

#Load singularity and nextflow modules
# See: https://opus.nci.org.au/display/DAE/Nextflow
# See: https://opus.nci.org.au/display/Help/Singularity
module load java
module load nextflow
module load singularity

# Fill in these variables for your run
ref= #full path to your reference.fasta
samples= #full path to your input.tsv file
annotsvDir= #full path to directory housing Annotations_Human directory
annotsvMode= #both|full|split. see annotation mode in https://github.com/lgmgeo/AnnotSV/blob/master/README.AnnotSV_3.3.4.pdf
outDir= #full path for results directory

# set singularity cache dir
export NXF_SINGULARITY_CACHEDIR=/scratch/$PROJECT/$(whoami)/singularity

# Run the pipeline (remove annotsv if not needed)
nextflow run main.nf \
	--input ${samples} -profile gadi \
	--ref ${ref} --annotsvDir ${annotsvDir} --annotsvMode ${annotsvMode} \
	--whoami $(whoami) --gadi_account $PROJECT \
	--outDir ${outDir}
