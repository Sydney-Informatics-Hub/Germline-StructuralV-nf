#!/bin/bash

#PBS -P er01
#PBS -N PG_6
#PBS -l walltime=48:00:00
#PBS -l ncpus=1
#PBS -l mem=190GB
#PBS -W umask=022
#PBS -q normalbw
#PBS -e ./testPG_full6_diskJOBFS.e
#PBS -o ./testPG_full6_diskJOBFS.o
#PBS -l wd
#PBS -l storage=scratch/er01+gdata/er01

#Load singularity and nextflow modules
# See: https://opus.nci.org.au/display/DAE/Nextflow
# See: https://opus.nci.org.au/display/Help/Singularity
module load singularity
module load nextflow

# Fill in these variables for your run
ref=/scratch/er01/gs5517/workflowDev/Reference/hs38DH.fasta #full path to your reference.fasta
samples=/scratch/er01/gs5517/workflowDev/Germline-StructuralV-nf/platinumgenomes.tsv #samplesheet.tsv #platinumgenomes_1.tsv #full path to your input.tsv file
annotSV=/scratch/er01/gs5517/workflowDev/Germline-StructuralV-nf/AnnotSV #full path to directory housing Annotations_Human directory
uid=gs5517 #your gadi user name i.e. xx1111
project=er01 #relevant code for accounting i.e. xx00
outDir=/scratch/er01/gs5517/workflowDev/Germline-StructuralV-nf/results #full path for results directory

# Run the pipeline (remove annotsv if not needed)
nextflow run main.nf \
	--input ${samples} \
	--ref ${ref} --annotsv ${annotSV} \
	-profile gadi --whoami ${uid} --pbs_account ${project} \
	--outDir ${outDir}
