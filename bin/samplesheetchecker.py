#!/usr/bin/env python3

import csv
import sys
from pathlib import Path

def check_file_exists(file_path):
    return Path(file_path).is_file()

def validate_samplesheet(samplesheet_path):
    # Check if the samplesheet path is correct
    if not Path(samplesheet_path).is_file():
        print("Error: Invalid path to samplesheet.")
        sys.exit(1)

    # Open the samplesheet csv
    with open(samplesheet_path, 'r') as file:
        reader = csv.reader(file)
        headers = next(reader)  # Read the header

        # Check if the header matches the expected format
        expected_header = ['sample', 'bam', 'bai']
        if headers != expected_header:
            print("Error: Invalid header format.")
            sys.exit(1)

        # Check columns for all rows are csv
        for row in reader:
            for column in row:
                if '\t' in column:
                    print("Error: Found a column with a tab delimiter, expected csv.")
                    sys.exit(1)

def modify_samplesheet(samplesheet_path):
    output_csv = sys.argv[2]
    output_header = ['sample', 'bam', 'bai']

    with open(samplesheet_path, 'r') as file:
        reader = csv.reader(file)
        headers = next(reader)  # Read the header

        rows = []
        for row in reader:
            bam = row[1]
            bai = row[2]

    with open(output_csv, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(output_header)
        writer.writerows(rows)

def main():
    input_csv = sys.argv[1]

    # Validate samplesheet
    validate_samplesheet(input_csv)

    # Modify samplesheet
    modify_samplesheet(input_csv)

if __name__ == "__main__":
    main()
