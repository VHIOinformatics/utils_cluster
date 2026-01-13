#!/bin/bash
#SBATCH --job-name=example  # Job name
#SBATCH -p long
#SBATCH --mail-type=END,FAIL          # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=paumunoz@vhio.net     # Where to send mail	
#SBATCH --ntasks=1                    # Run on a single CPU
#SBATCH --mem=8G                     # Job memory request
#SBATCH --cpus-per-task=1
#SBATCH --output=%x_%j.log   # Standard output and error lo
#SBATCH --error=%x_%j.err
#SBATCH -w bioinf3.vhio.org #OPTIONAL, IN CASE YOU ONLY NEED SPECIFIC NODES


#Variable definition
samples="Samplefile.csv"
version="xxx"
pipeline="nf-core/xxx"
profile="singularity"
genome="GATK.GRCh38"
tools="xxxxx"
sarekoutput="results_"$SLURM_JOB_NAME
logdir="XXXXX"
logfile=$SLURM_JOB_NAME".txt"
other=""
igenomes='/mnt/bioinfnas/general/refs/igenomes'

#Maximum resources
maxmem="74.GB"
max_cpu="30"
max_time="12.h"

#Nextflow command
cmd="nextflow run $pipeline -profile $profile --input $samples -c nextflow.conf  --genome $genome -r $version --tools $tools --igenomes_base $igenomes --outdir $sarekoutput $other"


#Creation of cache directory to store images downloaded by the pipeline
if [ ! -d "cache" ]
then
	mkdir cache
fi

if [! -d "./tmp"]
then
	mkdir ./tmp
else
	rm -rf ./tmp/*
fi



#Creation of Nextflow config file
read -r -d '' config <<- EOM

#Config parameters
params {
  config_profile_description = 'bioinfo config'
  config_profile_contact = '$SLURM_JOB_USER $SLURM_JOB_USER@vhio.net'
  config_profile_url ='tobecopiedingithub'
}
#Singularity configuration
singularity {
  enabled = true
  autoMounts = true
  cacheDir='./cache/'
  runOptions = '-B ./tmp/'
}
env{
	  TMPDIR="./tmp/"

}
#Slurm queue configuration
executor {
  name = 'slurm'
  queueSize = 12 #Number of maximum processes executed at the same time
}

#Slurm partitions configuration: each job will be sent to a specific partition according to resources needed defined by the pipeline
process { 
  executor = 'slurm'
  queue    = { task.time <= 5.h && task.memory <= 10.GB ? 'short': (task.time >= 10.d || task.memory < 72.GB ? 'long' : 'highmem')}
#  clusterOptions = { " -w bioinf.vhio.org --exclude=bioinf2.vhio.org"}    ####OPTIONAL, ONLY USE IN CASE YOU NEED TO LAUNCH THE JOB IN SPECIFIC NODES


}

#Definition of maximum resources
params {
  max_memory = '$maxmem'
  max_cpus = $max_cpu
  max_time = '$max_time'
}
EOM

echo "$config" > nextflow.conf


#Adding information about this run in the project's log 
message=$(date +"%D %T")"        "$(whoami)"     "$SLURM_JOB_NAME"       "$cmd
echo  $message >> $logdir$logfile
$cmd
tail -n 20 $SLURM_JOB_NAME"_"$SLURM_JOB_ID".log" >> $logdir$logfile

