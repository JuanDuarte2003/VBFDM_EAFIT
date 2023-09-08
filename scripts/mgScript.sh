#!/bin/bash

# $1 -> MadGraph process directory
# $2 -> gSxd value
# $3 -> gSq value
# $4 -> gSg1 value
# $5 -> gSg2 value

if [ $# -eq 0 ];
then
    echo "$0: Missing arguments"
    exit 1
elif [ $# -gt 5 ];
then
    echo "$0: Too many arguments: $@"
    exit 1
else
    mgDir=$1
fi

# Initial parameters for the param_card
declare -A couplingDic=(
    [gSXd]="${2}e+00"
    [gSd11]="${3}e+00"
    [gSu11]="${3}e+00"
    [gSd22]="${3}e+00"
    [gSu22]="${3}e+00"
    [gSd33]="${3}e+00"
    [gSu33]="${3}e+00"
    [Lambda]="1.000000e+04"
    [gSg1]="${4}e+00"
    [gSg2]="${5}e+00"
    [gSh1]="0.000000e+00"
    [gSh2]="0.000000e+00"
    [gSh3]="0.000000e+00"
    [gSb]="0.000000e+00"
    [gSw]="0.000000e+00"
)

# paths
rcPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Cards/run_card.dat"
pcPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Cards/param_card.dat"
binPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/bin/generate_events"
eventPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Events/"

mlPath="./massList.txt"
logPath="../registers/"
outPath="../ToSCP/csv/"

#echo -e "${rcPath}\n${pcPath}\n${binPath}\n${eventPath}\n${mlPath}\n${logPath}"
#for key in "${!couplingDic[@]}"; do
#    echo -e "${key}:\t${couplingDic[$key]}"
#done

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

modParamCard () {
    # Modify the param_card ($1 -> mx, $2 -> my)
#    echo -e "$1,\t$2"
    tempPath='temp.dat'
    cp $pcPath $tempPath
    declare -a tempLines
    mapfile -t tempLines < $tempPath


    for i in "${!tempLines[@]}"; do
        if [[ "${tempLines[i]}" == *" # MXd"* ]]; then
            tempLines[i]="      52 $1 # MXd"
        fi
        if [[ "${tempLines[i]}" == *" # MY0"* ]]; then
            tempLines[i]="      54 $2 # MY0"
        fi
    done

    rm $pcPath

    for line in "${tempLines[@]}"; do
        echo "${line}" >> "$pcPath"
    done

    cp -r $tempPath $logPath
    rm $tempPath
}

initParamCard () {
    # Initialize the parameters in the param_card
    tempPath='temp.dat'
    cp $pcPath $tempPath
    declare -a tempLines
    mapfile -t tempLines < $tempPath

    for i in "${!tempLines[@]}"; do
        for key in "${!couplingDic[@]}"; do
            if [[ "${tempLines[i]}" == *"${key}"* ]]; then
		#echo -e "${tempLines[i]}"
                numCoupling=($(echo "${tempLines[i]}" | awk '{print $1}'))
                #echo -e "\n${numCoupling}\n"
                tempLines[i]="      ${numCoupling} ${couplingDic[$key]} # ${key}"
            fi
        done
    done
    
    rm $pcPath

    for line in "${tempLines[@]}"; do
        echo "${line}" >> "$pcPath"
    done

    rm $tempPath
}

echo -e "\n\n\t\tEvents of $mgDir\n\n"

echo -e "\tInitializing param_card\n"
initParamCard

declare -a massx
declare -a massy

echo -e "\tReading masses\n"
while IFS=$'\t' read -r mx my; do
    massx+=($mx)
    massy+=($my)
done < "${mlPath}"

numExistingRuns=$(find "$eventPath" -mindepth 1 -maxdepth 1 -type d | wc -l)

runCont=$((numExistingRuns + 1))

if [[ "$numExistingRuns" != 0 ]]; then
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\tThere is $numExistingRuns saved runs\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

echo -e "\tStarting generation\n"

for massIndex in "${!massx[@]}"; do
    echo -e "\tModifying run_card\n"
    modRunCard
    echo -e "\tModifying param_card\n"
    modParamCard "${massx[massIndex]}" "${massy[massIndex]}"
    echo -e "\n\n\t\t\tGenerating Events with mx=${massx[massIndex]} and my=${massy[massIndex]}\n\n"
    $binPath -f
    rootPath="${eventPath}run_${runCont}/tag_1_delphes_events.root"
    outputPath="${outPath}${mgDir}_${runCont}"
    echo -e "\tSaving run in CSV\n"
    python3 -c "import expCSV; expCSV.export_to_csv(${rootPath},${outPath})"
    ((runCont++))
done
