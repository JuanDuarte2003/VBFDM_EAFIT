#!/bin/bash

# $1 -> MadGraph process directory
# $2 -> number of Runs to do
# $3 -> Manual offset

if [ $# -eq 0 ];
then
    echo "$0: Missing arguments"
    exit 1
elif [ $# -gt 3 ];
then
    echo "$0: Too many arguments: $@"
    exit 1
else
    mgDir=$1
    totalRuns=$2
    offset=$3
fi

# paths
rcPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Cards/run_card.dat"
pcPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Cards/param_card.dat"
binPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/bin/madevent"
eventPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Events/"

logPath="../registers/"
outPath="../ToSCP/csv/"

modRunCard () {
    # Modify the run_card
    tempPath='temp.dat'
    cp $rcPath $tempPath
    declare -a tempLines
    mapfile -t tempLines < $tempPath

    for i in "${!tempLines[@]}"; do
        if [[ "${tempLines[i]}" == *"= iseed"* ]]; then
            seed=$(( $RANDOM % 65000))
            tempLines[i]="  ${seed}  = iseed  ! rnd seed (0=assigned automatically=default)"
	elif [[ "${tempLines[i]}" == *"= nevents"* ]]; then
	    tempLines[i]="  50000 = nevents ! Number of unweighted events requested"
	elif [[ "${tempLines[i]}" == *"= use_syst"* ]]; then
            tempLines[i]="  False  = use_syst      ! Enable systematics studies"
	fi
    done
    
    rm $rcPath

    for line in "${tempLines[@]}"; do
        echo -e "${line}" >> "$rcPath"
    done

    rm $tempPath
}

echo -e "\n\n\t\tBackground Events of $mgDir\n\n"
echo -e "\t Runs: $totalRuns"

numExistingRuns=$(find "$eventPath" -mindepth 1 -maxdepth 1 -type d | wc -l)

runCont=$((numExistingRuns + 1))

if [[ "$numExistingRuns" != 0 ]]; then
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\tThere is $numExistingRuns saved runs\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

echo -e "\tStarting generation\n"

cont=1

while [[ "$cont" -le "$totalRuns" ]]; do
    echo -e "\tModifying run_card\n"
    modRunCard
    echo -e "\n\n\t\t\tGenerating Events (Run:${cont}/${totalRuns})\n\n"
    $binPath gen_events.sh
    if [[ $runCont -lt 10 ]]; then
	    #echo -e "Test: runCont < 10"
	    rootPath="${eventPath}run_0${runCont}/tag_1_delphes_events.root"
    else
	    rootPath="${eventPath}run_${runCont}/tag_1_delphes_events.root"
    fi
    runSave=$((runCont+offset))
    outputPath="${outPath}${mgDir}_${runSave}.csv"
    echo -e "\tSaving run in CSV\n"
    echo -e "\nrootPath='${rootPath}'\noutputPath='${outputPath}'"
    python3 -c "import expCSV; expCSV.export_to_csv('${rootPath}','${outputPath}', n_jets=4, n_lep=4)"
    ((runCont++))
    ((cont++))
done
