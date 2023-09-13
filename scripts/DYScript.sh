#!/bin/bash

# paths
rcPath='../MadGraph/MG5_aMC_v3_5_1/DYpJets/Cards/run_card.dat'
binPath='../MadGraph/MG5_aMC_v3_5_1/DYpJets/bin/generate_events'
logPath='../registers/'

modRunCard () {
    # Modifica la run_card
    tempPath='temp.dat'
    cp $rcPath $tempPath
    declare -a tempLines
    mapfile -t tempLines < $tempPath

    for i in "${!tempLines[@]}"; do
        if [[ "${tempLines[i]}" == *"= iseed"* ]]; then
            seed=$(( $RANDOM % 65000))
            tempLines[i]="  ${seed}  = iseed  ! rnd seed (0=asssigned automatically=default)"
        fi
    done

    rm $rcPath

    for line in "${tempLines[@]}"; do
        echo -e "${line}" >> "$rcPath"
    done

    rm $tempPath
}

modRunCard
echo -e "\n\n\n\t\t\tGenerating Drell-Yan Events\n\n\n"
$binPath -f
