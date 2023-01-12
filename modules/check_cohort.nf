process checkInputs {
// no publishDir specified as no need to recreate samples.tsv 
// TODO write python script to check integrity of file
// confirm tab separated, confirm correct number of columns
// Confirm bams exist 
	
	input:
	path input

	output:
	file "samples.txt"
		
	script:
	"""
	cat "${params.input}" > samples.txt
	"""
}
