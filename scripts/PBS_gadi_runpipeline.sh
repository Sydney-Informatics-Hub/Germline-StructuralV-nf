#!/bin/bash

#PBS -P
#PBS -N
#PBS -l walltime=48:00:00
#PBS -l ncpus=1
#PBS -l mem=190GB
#PBS -W umask=022
#PBS -q normal
#PBS -e germlineStructuralV-nf.e
#PBS -o germlineStructuralV-nf.o
#PBS -l wd
#PBS -l storage=

#Load singularity and nextflow modules
# See: https://opus.nci.org.au/display/DAE/Nextflow
# See: https://opus.nci.org.au/display/Help/Singularity
module load singularity
module load nextflow/23.04.1
module load java

# Fill in these variables for your run
ref= #full path to your reference.fasta
samples= #platinumgenomes_1.tsv #full path to your input.tsv file
annotsvDir= #full path to directory housing Annotations_Human directory
annotsvMode= #see annotation mode in https://github.com/lgmgeo/AnnotSV/blob/master/README.AnnotSV_3.3.4.pdf
outDir= #full path for results directory

# set singularity cache dir
export NXF_SINGULARITY_CACHEDIR=/scratch/$PROJECT/$(whoami)/singularity

# Run the pipeline (remove annotsv if not needed)
nextflow run main.nf \
	--input ${samples} -profile gadi \
	--ref ${ref} --annotsvDir ${annotsvDir} --annotsvMode ${annotsvMode} \
	--whoami $(whoami) --pbs_account $PROJECT \
	--outDir ${outDir}
