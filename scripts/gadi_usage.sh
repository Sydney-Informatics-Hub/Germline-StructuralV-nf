#!/bin/bash

#------------------------------------------------------------------
# gadi_usage/1.0
# Platform: NCI Gadi HPC
#
# Description:
# This script gathers the job requests and usage metrics from Gadi log
# files hidden in nextflow work directories for a collection of job log
# files within the current directory, and calculates efficiency values
# using the formula e = cputime/walltime/cpus_used.
#
# Usage:
# command line, eg:
# bash gadi_usage.sh
#
# Output:
# Tab-delimited summary of the resources requested and used for each job
# will be printed to tsv file: gadi-gsv-usage-report.tsv.
#
# Date last modified: 31/10/23
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#------------------------------------------------------------------

# File to save the parsed results
usage_file="gadi-gsv-usage-report.tsv"

# Initialise the result file with headers
echo -e "Log_path\tExit_status\tService_units\tNCPUs_requested\tNCPUs_used\tCPU_time_used\tMemory_requested\tMemory_used\tWalltime_requested\tWalltime_used\tJobFS_requested\tJobFS_used" > "$usage_file"

# Find and process .command.log files
find work -type f -name ".command.log" | while read -r log_file; do
    file_name=$(echo "$log_file")

    # Extract the information and append to usage_file
    awk '
    BEGIN {
        name= "NA"
        exit_status = "NA"
        service_units = "NA"
        ncpus_requested = "NA"
        ncpus_used = "NA"
        cpu_time_used = "NA"
        memory_requested = "NA"
        memory_used = "NA"
        walltime_requested = "NA"
        walltime_used = "NA"
        jobfs_requested = "NA"
        jobfs_used = "NA"
    }
    /=====/ {flag=!flag; next}
    flag {
        if($0 ~ /Exit Status/) exit_status = $3
        if($0 ~ /Service Units/) service_units = $3
        if($0 ~ /NCPUs Requested/) ncpus_requested = $3
        if($0 ~ /NCPUs Used/) ncpus_used = $3
        if($0 ~ /CPU Time Used/) cpu_time_used = $5
        if($0 ~ /Memory Requested/) memory_requested = $3
        if($0 ~ /Memory Used/) memory_used = $6
        if($0 ~ /Walltime requested/) walltime_requested = $3
        if($0 ~ /Walltime Used/) walltime_used = $6
        if($0 ~ /JobFS requested/) jobfs_requested = $3
        if($0 ~ /JobFS used/) jobfs_used = $6
    }
    END {
        print "'$file_name'", exit_status, service_units, ncpus_requested, ncpus_used, cpu_time_used, memory_requested, memory_used, walltime_requested, walltime_used, jobfs_requested, jobfs_used
    }' OFS="\t" $log_file >> $usage_file
done

echo "Results have been parsed to $usage_file."
