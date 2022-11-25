# GermlineStructuralV-nf

<p align="center">
:wrench: This pipeline is currently under development :wrench:
</p>

  - [Description](#description)
  - [Diagram](#diagram)
  - [User guide](#user-guide)
      - [Infrastructure usage and
        recommendations](#infrastructure-usage-and-recommendations)
  - [Benchmarking](#benchmarking)
  - [Workflow summaries](#workflow-summaries)
      - [Metadata](#metadata)
      - [Component tools](#component-tools)
  - [Additional notes](#additional-notes)
  - [Help/FAQ/Troubleshooting](#helpfaqtroubleshooting)
  - [Acknowledgements/citations/credits](#acknowledgementscitationscredits)

## Description 

GermlineStructuralV-nf is a Nextflow pipeline for identifying structural variant events in Illumina short read whole genome sequence data. GermlineStructuralV-nf identifies structural variant and copy number events from BAM files using [Manta](https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md#de-novo-calling), [Smoove](https://github.com/brentp/smoove), and [TIDDIT](https://github.com/SciLifeLab/TIDDIT). Variants are then merged using [SURVIVOR](https://github.com/fritzsedlazeck/SURVIVOR), and annotated by [Variant Effect Predictor](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-016-0974-4) (VEP). The pipeline is written in Nextflow and uses Singularity to run containerised tools, making it a portable, reproducible, and scalable solution. 

Structural and copy number detection is challenging. Most structural variant detection tools infer these events from read mapping patterns, which can often resemble sequencing and read alignment artefacts. To address this, GermlineStructuralV-nf employs 3 general purpose structural variant calling tools, which each support a combination of detection methods. Manta, Smoove and TIDDIT use typical detection approaches that consider: 

* Discordant read pair alignments  
* Split reads that span a breakpoints
* Read depth profiling 
* Local de novo assembly  

This approach is currently considered best practice for maximising sensitivty of short read data [Cameron et al. (2019)](https://www.nature.com/articles/s41467-019-11146-4), [Malmoud et al. (2019)](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1828-7). By using a combination of tools that employ different methods, we improve our ability to detect different types and sizes of variant events, as described below: 

<INSERT TABLE COMPARING CALLERS > 

## Diagram

<p align="center"> 
<img src="https://user-images.githubusercontent.com/73086054/187623685-133bc241-0187-4c0f-9821-c22ef1415a9a.png" width="80%">
</p> 

## User guide 

To run this pipeline, you will need to prepare your input files, reference data, and clone this repository. Before proceeding, ensure Nextflow is installed on the system you're working on. To install Nextflow, see these [instructions](https://www.nextflow.io/docs/latest/getstarted.html#installation). 

### 1. Prepare inputs

To run this pipeline you will need the following inputs: 

* Paired-end BAM files
* Corresponding BAM index files  
* Input sample sheet 

This pipeline processes paired-end BAM files and is capable of processing multiple samples in parallel. BAM files are expected to be coordinate sorted and indexed (see [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) for an example of a best practice workflow that can generate these files).  

You will need to create a sample sheet with information about the samples you are processing, before running the pipeline. This file must be **tab-separated** and contain a header and one row per sample. Columns should correspond to sampleID, BAM file, BAI file: 

|sampleID|bam                   |bai                       |
|--------|----------------------|--------------------------|
|SAMPLE1 |/data/Bams/sample1.bam|/data/Bams/sample1.bam.bai|
|SAMPLE2 |/data/Bams/sample2.bam|/data/Bams/sample2.bam.bai|

When you run the pipeline, you will use the mandatory `--input` parameter to specify the location and name of the input file: 

```
--input /path/to/samples.tsv
```

### 2. Prepare the reference materials 

To run this pipeline you will need the following reference files:

* Indexed reference genome in FASTA format 
* [VEP cache](https://asia.ensembl.org/info/docs/tools/vep/script/vep_cache.html#cache) (Optional) 

You will need to download and index a copy of the reference genome you would like to use. Reference FASTA files must be accompanied by a .fai index file. If you are working with a species that has a public reference genome, you can download FASTA files from the [Ensembl](https://asia.ensembl.org/info/data/ftp/index.html), [UCSC](https://genome.ucsc.edu/goldenPath/help/ftp.html), or [NCBI](https://www.ncbi.nlm.nih.gov/genome/doc/ftpfaq/) ftp sites. You can use our [IndexReferenceFasta-nf pipeline](https://github.com/Sydney-Informatics-Hub/IndexReferenceFasta-nf) to generate indexes. 

When you run the pipeline, you will use the mandatory `--ref` parameter to specify the location and name of the reference.fasta file: 

```
--ref /path/to/reference.fasta
```

If you intend to run the optional step of variant annotation with VEP, you will need to manually download a cache of the VEP database before running the pipeline (if available for your organism). See [these instructions](https://asia.ensembl.org/info/docs/tools/vep/script/vep_cache.html#cache) for how to prepare your data and [Ensembl's VEP ftp site](https://ftp.ensembl.org/pub/release-108/variation/indexed_vep_cache/), for available databases. In short, you will need to do the following: 

**Create a local cache directory** 

Be aware, the VEP cache requires a lot of disk space, for example the Hg38 108 release database requires ~21G. Because of this it is essential to create this directory somewhere with enough disk space to store it. Create the directory:  
```
mkdir -p <name of cache directory>
```

**Download a copy of the cache**

Download the cache to your cache directory. For example:  
```
wget -P <name of cache directory> ftp://ftp.ensembl.org/pub/release-108/variation/indexed_vep_cache/homo_sapiens_vep_108_GRCh38.tar.gz
```

Unzip it: 

```
tar xzf homo_sapiens_vep_108_GRCh38.tar.gz
```

When you run the pipeline, if you would like to perform variant annotation with VEP, you will use the `--VEPcache` parameter to specify the location and name of the input file: 

```
--VEPcache /path/to/VEP_cache 
```

### 3. Clone this repository 

Download the code contained in this repository with: 

```
git clone https://github.com/Sydney-Informatics-Hub/Germline-StructuralV-nf
```

This will create a directory with the following structure: 
```
Germline-StructuralV-nf/
├── LICENSE
├── README.md
├── config/
├── main.nf
├── modules/
└── nextflow.config
```
The important features are: 

* **main.nf** contains the main nextflow script that calls all the processes in the workflow.
* **nextflow.config** contains default parameters to use in the pipeline.
* **modules** contains individual process files for each step in the workflow. 
* **config** contains infrastructure-specific config files (this is currently under development)

### 4. Run the pipeline 

The most basic run command for this pipeline is: 

```
nextflow run main.nf --input sample.tsv --ref /path/to/ref 
```

By default, this will generate `work` directory, `results` output directory and a `runInfo` run metrics directory in the same location you ran the pipeline from. 

To specify additional optional tool-specific parameters, see what flags are supported by running:

```
nextflow run main.nf --help 
```

If for any reason your workflow fails, you are able to resume the workflow from the last successful process with `-resume`. 

## Infrastructure useage and recommendations 

Coming soon! 

## Benchmarking 

Coming soon!

## Workflow summaries
### Metadata 

|metadata field     | GermlineStructuralV-nf / v1.0     |
|-------------------|:--------------------------------- |
|Version            | 1.0                               |
|Maturity           | under development                 |
|Creators           | Georgie Samaha                    |
|Source             | NA                                |
|License            | GNU General Public License v3.0   |
|Workflow manager   | NextFlow                          |
|Container          | See Component tools               |
|Install method     | NA                                |
|GitHub             | https://github.com/Sydney-Informatics-Hub/Germline-StructuralV-nf                            |
|bio.tools 	        | NA                                |
|BioContainers      | NA                                | 
|bioconda           | NA                                |

### Component tools 

To run this pipeline you must have Nextflow and Singularity installed on your machine. All other tools are run using containers. 

|Tool         | Version  |
|-------------|:---------|
|Nextflow     |>=20.07.1 |
|Singularity  |          |
|Manta        |1.6.0     |
|Smoove       |0.2.7     |
|TIDDIT       |3.3.1     |
|BCFtools     |1.15.1    |
|HTSlib       |1.15.1    |
|SURVIVOR     |1.0.7     |
|VEP          |108       |
|R            |          |


## Additional notes 
### Resources 

* [Nextflow documentation](https://www.nextflow.io/docs/latest/index.html) 

### Help/FAQ/Troubleshooting

* It is essential that the reference genome you're using contains the same chromosomes, contigs, and scaffolds as the BAM files. This is [mandated by Manta](https://github.com/Illumina/manta/issues/92), which will throw an error if the BAM and FASTA files do not match. To confirm what contigs are included in your indexed BAM file, you can use Samtools idxstats: 
```
samtools idxstats input.bam | cut -f 1
```

## Acknowledgements/citations/credits
### Authors 
- Georgie Samaha (Sydney Informatics Hub, University of Sydney)   

### Acknowledgements 

- This pipeline was built using the [Nextflow DSL2 template](https://github.com/Sydney-Informatics-Hub/Nextflow_DSL2_template).  
- Documentation was created following the [Australian BioCommons documentation guidelines](https://github.com/AustralianBioCommons/doc_guidelines).  

### Cite us to support us! 
Acknowledgements (and co-authorship, where appropriate) are an important way for us to demonstrate the value we bring to your research. Your research outcomes are vital for ongoing funding of the Sydney Informatics Hub and national compute facilities. We suggest including the following acknowledgement in any publications that follow from this work:  

The authors acknowledge the technical assistance provided by the Sydney Informatics Hub, a Core Research Facility of the University of Sydney and the Australian BioCommons which is enabled by NCRIS via Bioplatforms Australia. 
