#!/bin/bash
#SBATCH --job-name=example  # Job name
#SBATCH -p long
#SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=user@vhio.net     # Where to send mail	
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --mem=8G                     # Job memory request
#SBATCH --cpus-per-task=1
#SBATCH --output=%x_%j.log   # Standard output and error lo
#SBATCH --error=%x_%j.err
#SBATCH -w bioinf3.vhio.org #OPTIONAL, IN CASE YOU ONLY NEED SPECIFIC NODES


#Variable definition
pipeline="nf-core/xxx"
version="xxx"
profile="singularity"
samples="Samplefile.csv"
output="results_"$SLURM_JOB_NAME
igenomes='/mnt/petasan_general_bioinformatics_R/refs/igenomes/' #Only if using iGenomes (not recommended for transcriptomics)
genome="GATK.GRCh38" #Only if using iGenomes
other=""


#Nextflow command
cmd="nextflow run $pipeline -r $version -profile $profile --input $samples -c nextflow.conf --igenomes_base $igenomes --genome $genome --outdir $output $other"


#Creation of cache directory to store images downloaded by the pipeline
if [ ! -d "cache" ]
then
	mkdir cache
fi


#Creation of tmp dir to save temporary files in the working directory instead of the computation nodes
if [! -d "./tmp"]
then
	mkdir ./tmp
else
	rm -rf ./tmp/*
fi


#Creation of Nextflow config file
read -r -d '' config <<- EOM

//Config parameters
params {
  config_profile_description = 'bioinfo config'
  config_profile_contact = '$SLURM_JOB_USER $SLURM_JOB_USER@vhio.net'
  config_profile_url ='tobecopiedingithub'
}

//Singularity configuration
singularity {
  enabled = true
  autoMounts = true
  cacheDir='./cache/'
  runOptions = '-B ./tmp/'
}
env{
	  TMPDIR="./tmp/"

}

//Slurm queue configuration
executor {
  name = 'slurm'
  queueSize = 12 //Number of maximum processes executed at the same time
}

//Slurm partitions configuration: each job will be sent to a specific partition according to resources needed defined by the pipeline
process { 
  executor = 'slurm'
  queue    = { task.time <= 5.h && task.memory <= 10.GB ? 'short': (task.time >= 10.d || task.memory < 72.GB ? 'long' : 'highmem')}
  //clusterOptions = { " -w bioinf.vhio.org --exclude=bioinf2.vhio.org"}    //OPTIONAL, ONLY USE IN CASE YOU NEED TO LAUNCH THE JOB IN SPECIFIC NODES
}
EOM

echo "$config" > nextflow.conf


#Run command
$cmd
