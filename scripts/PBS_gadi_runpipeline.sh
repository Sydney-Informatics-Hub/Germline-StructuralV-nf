#!/bin/bash

#PBS -P er01
#PBS -N PG_6bench
#PBS -l walltime=48:00:00
#PBS -l ncpus=1
#PBS -l mem=190GB
#PBS -W umask=022
#PBS -q normal
#PBS -e ./PG_benchmark.e
#PBS -o ./PG_benchmark.o
#PBS -l wd
#PBS -l storage=scratch/er01+gdata/er01

#Load singularity and nextflow modules
# See: https://opus.nci.org.au/display/DAE/Nextflow
# See: https://opus.nci.org.au/display/Help/Singularity
module load singularity
module load nextflow/23.04.1
module load java

# Fill in these variables for your run
ref=/scratch/er01/gs5517/workflowDev/Reference/hs38DH.fasta #full path to your reference.fasta
samples=/scratch/er01/gs5517/workflowDev/Germline-StructuralV-nf/samplesheet.tsv #platinumgenomes_1.tsv #full path to your input.tsv file
annotsv=/scratch/er01/gs5517/workflowDev/Germline-StructuralV-nf/AnnotSV #full path to directory housing Annotations_Human directory
outDir=/scratch/er01/gs5517/workflowDev/Germline-StructuralV-nf/Benchmarking/results #full path for results directory

# set singularity cache dir
export NXF_SINGULARITY_CACHEDIR=/scratch/$PROJECT/$(whoami)/singularity

# Run the pipeline (remove annotsv if not needed)
nextflow run main.nf \
	--input ${samples} -profile gadi \
	--ref ${ref} --annotsvDir ${annotsv} \
	 --whoami $(whoami) --pbs_account $PROJECT \
	--outDir ${outDir}
