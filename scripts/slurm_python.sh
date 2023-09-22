#!/bin/bash

#SBATCH --partition=learning                   # Partition
#SBATCH --nodes=1
#SBATCH --ntasks=1                              # Number of tasks (processes)
#SBATCH --time=3-00:00:00                           # Walltime
#SBATCH --job-name=VBFDM_EAFIT       		# Job name
#SBATCH --output=outputs/%x_%j.out 			# Stdout (%x-jobName, %j-jobId)
#SBATCH --error=errors/%x_%j.err  			# Stderr (%x-jobName, %j-jobId)
#SBATCH --mail-type=all		                # Mail notification
#SBATCH --mail-user=jmduarteq@eafit.edu.co       # User Email


##### ENVIRONMENT CREATION #####
module load python-3.9.10-gcc-9.3.0-jhmdlwn
pip install awkward
pip install pandas
pip install numpy
pip install coffea
pip install vector

##### JOB COMMANDS ####
cd scripts/
#./massListGenerator.sh
echo -e "\n\n\tGenerating background signals\n"
./bgScript.sh WpJets 10
./bgScript.sh ZpJets 10
# gSq = 1.0
#./mgScript.sh DM_gSq_only 1.0 1.0 0.0 0.0
#wait
# gSg1 = 1.0
#./mgScript.sh DM_gSg1_only 1.0 0.0 1.0 0.0
#wait
# gSg2 = 1.0
#./mgScript.sh DM_gSg2_only_y0y0 1.0 0.0 0.0 1.0
#wait
# gSg1 = 1.0, gSg2 = 1.0
#./mgScript.sh DM_gSg_only 1.0 0.0 1.0 1.0

