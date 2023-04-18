#!/bin/bash -l 
#SBATCH --job-name=GSV
#SBATCH --account=XXXX
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4000M
#SBATCH --nodes=1
#SBATCH --time=10:00:00
#SBATCH --mail-user=XXXX
#SBATCH --mail-type=ALL

#Load singularity and nextflow modules. The specific version numbers may change over time. 
#Check what modules are available with `module spider <tool_name>`

module load singularity/3.8.6-nompi
module load nextflow/22.04.3

#Run the pipeline
nextflow run main.nf --input samples.tsv --ref /path/to/reference/fasta -config config/setonix.config --annotsv Annotations_Human
