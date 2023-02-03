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

GermlineStructuralV-nf is a pipeline for identifying structural variant events in human Illumina short read whole genome sequence data. GermlineStructuralV-nf identifies structural variant and copy number events from BAM files using [Manta](https://github.com/Illumina/manta/blob/master/docs/userGuide/README.md#de-novo-calling), [Smoove](https://github.com/brentp/smoove), and [TIDDIT](https://github.com/SciLifeLab/TIDDIT). Variants are then merged using [SURVIVOR](https://github.com/fritzsedlazeck/SURVIVOR), and annotated by [AnnotSV](https://pubmed.ncbi.nlm.nih.gov/29669011/). The pipeline is written in Nextflow and uses Singularity/Docker to run containerised tools.

Structural and copy number detection is challenging. Most structural variant detection tools infer these events from read mapping patterns, which can often resemble sequencing and read alignment artefacts. To address this, GermlineStructuralV-nf employs 3 general purpose structural variant calling tools, which each support a combination of detection methods. Manta, Smoove and TIDDIT use typical detection approaches that consider: 

* Discordant read pair alignments  
* Split reads that span a breakpoints
* Read depth profiling 
* Local de novo assembly  

This approach is currently considered the best approach for maximising sensitivty of short read data ([Cameron et al. 2019](https://www.nature.com/articles/s41467-019-11146-4), [Malmoud et al. 2019](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1828-7)). By using a combination of tools that employ different methods, we improve our ability to detect different types and sizes of variant events.

## Diagram

<p align="center"> 
<img src="https://user-images.githubusercontent.com/73086054/211971740-772796bc-6fb7-43fb-885b-d9cb116bfdd0.png" width="80%">
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
* [AnnotSV annotation datasets](https://lbgi.fr/AnnotSV/) (Optional) 

You will need to download and index a copy of the reference genome you would like to use. Reference FASTA files must be accompanied by a .fai index file. If you are working with a species that has a public reference genome, you can download FASTA files from the [Ensembl](https://asia.ensembl.org/info/data/ftp/index.html), [UCSC](https://genome.ucsc.edu/goldenPath/help/ftp.html), or [NCBI](https://www.ncbi.nlm.nih.gov/genome/doc/ftpfaq/) ftp sites. You can use the [IndexReferenceFasta-nf pipeline](https://github.com/Sydney-Informatics-Hub/IndexReferenceFasta-nf) to generate required samtools and bwa indexes. 

When you run the pipeline, you will use the mandatory `--ref` parameter to specify the location and name of the reference.fasta file: 

```
--ref /path/to/reference.fasta
```

**Download the AnnotSV database and supporting files (optional)** 

If you choose to run the pipeline with [AnnotSV annotations](https://raw.githubusercontent.com/lgmgeo/AnnotSV/master/README.AnnotSV_3.2.pdf), you currently need to download and prepare the relevant AnnotSV files, manually. The AnnotSV data is very large (>20Gb) so we haven't included it in the AnnotSV container. 

First, download the AnnotSV database: 
```
wget https://www.lbgi.fr/~geoffroy/Annotations/Annotations_Human_3.2.1.tar.gz 
```

Then unzip it and save to a directory of your choosing: 
```
tar -xf Annotations_Human_3.2.1.tar.gz -C /path/to/AnnotSV
```

You will also need to download the Exomiser supporting data files: 
```
wget https://www.lbgi.fr/~geoffroy/Annotations/2202_hg19.tar.gz && wget https://data.monarchinitiative.org/exomiser/data/2202_phenotype.zip
```

Create a directory to house the Exomiser files: 
```
mkdir -p Annotations_Human/Annotations_Exomiser/2202
```

Save the downloaded Exomiser files to your AnnotSV directory: 
```
tar -xf 2202_hg19.tar.gz -C /path/to/AnnotSV/Annotations_Human/Annotations_Exomiser/2202/ && unzip 2202_phenotype.zip -d /path/to/AnnotSV/Annotations_Human/Annotations_Exomiser/2202/
```

And finally (optionally), tidy up: 
```
rm -rf Annotations_Human_3.2.1.tar.gz 2202_phenotype.zip 2202_hg19.tar.gz
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

This will generate `work` directory, `results` output directory and a `runInfo` run metrics directories. To specify additional optional tool-specific parameters, see what flags are supported by running:

```
nextflow run main.nf --help 
```

**AnnotSV annotations for human samples**

To run the pipeline with the optional AnnotSV annotations, use the following command: 

```
nextflow run main.nf --input sample.tsv --ref /path/to/ref --annotsv /path/to/annotsv
```

If for any reason your workflow fails, you are able to resume the workflow from the last successful process with `-resume`. 

### 5. Results 

Once the pipeline is complete, you will find all outputs for each sample in the `results` directory. Within each sample directory there is a subdirectory for each tool run which contains all intermediate files and results generated by each step. A final merged VCF for each sample will be created: `results/$sampleID/survivor/$sampleID_merged.vcf`.  

The following directories will be created: 

* manta: all intermediate files and results generated by Manta. 
* smoove: all intermediate files and results generated by Smoove. 
* tiddit: all intermediate files and results generated by Tiddit. 
* survivor: summary stats, merged multi-caller VCF (final output), merged multi-caller bedpe file.
* annotsv: full annotations for the all events in the merged multi-callr VCF.  

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
|AnnotSV      |3.2.1     |

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
- Tracy Chew (Sydney Informatics Hub, University of Sydney)
- Marina Kennerson (ANZAC Research Institute)
- Sarah Beecroft (Pawsey Supercomputing Research Centre)

### Acknowledgements 
- This pipeline was devloped and tested using data provided by the Northcott Neuroscience Laboratory, ANZAC Research Institute and resources provided by the Australian BioCommons 'Bring Your Own Data' platforms project and the Pawsey Supercomputing Research Centre. 
- This pipeline was built using the [Nextflow DSL2 template](https://github.com/Sydney-Informatics-Hub/Nextflow_DSL2_template).  
- Documentation was created following the [Australian BioCommons documentation guidelines](https://github.com/AustralianBioCommons/doc_guidelines).  

### Cite us to support us! 
Acknowledgements (and co-authorship, where appropriate) are an important way for us to demonstrate the value we bring to your research. Your research outcomes are vital for ongoing funding of the Sydney Informatics Hub and national compute facilities. We suggest including the following acknowledgement in any publications that follow from this work:  

The authors acknowledge the technical assistance provided by the Sydney Informatics Hub, a Core Research Facility of the University of Sydney and the Australian BioCommons which is enabled by NCRIS via Bioplatforms Australia. 
