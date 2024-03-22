#!/bin/bash

# $1 -> gVxd value
# $2 -> gVq value
# $3 -> number of Runs to do for each mass point
# $4 -> Manual offset for numbering output runs

if [ $# -eq 0 ];
then
    echo "$0: Missing arguments"
    exit 1
elif [ $# -gt 7 ];
then
    echo "$0: Too many arguments: $@"
    exit 1
else
    mgDir="DMspin1_gSq_only"
    totalRuns=$3
    offset=$4
fi

# Initial parameters for the param_card
declare -A couplingDic=(
    [gVXd]="${1}e+00"
    [gVd11]="${2}e+00"
    [gVu11]="${2}e+00"
    [gVd22]="${2}e+00"
    [gVu22]="${2}e+00"
    [gVd33]="${2}e+00"
    [gVu33]="${2}e+00"
)

# paths
rcPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Cards/run_card.dat"
pcPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Cards/param_card.dat"
binPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/bin/madevent"
eventPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/Events/"
htmlDirPath="../MadGraph/MG5_aMC_v3_5_1/${mgDir}/HTML/"

mlPath="./massList.txt"
logPath="../registers/"
outPath="../ToSCP/csv/"
outHTMLPath="../ToSCP/html/"

#echo -e "${rcPath}\n${pcPath}\n${binPath}\n${eventPath}\n${mlPath}\n${logPath}"
#for key in "${!couplingDic[@]}"; do
#    echo -e "${key}:\t${couplingDic[$key]}"
#done

modRunCard () {
    # Modify the run_card
    echo -e "\tModifying run_card\n"
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
    echo -e "\tModifying param_card\n"
    echo -e "$1,\t$2"
    tempPath='temp.dat'
    cp $pcPath $tempPath
    declare -a tempLines
    mapfile -t tempLines < $tempPath


    for i in "${!tempLines[@]}"; do
#	echo -e "${tempLines[i]}"
        if [[ "${tempLines[i]}" == *" # mxd"* ]]; then
	    echo -e "\ntest:\t${tempLines[i]}\n"
            tempLines[i]="      5000521 $1 # mxd"
	    echo -e "\ntest:\t${tempLines[i]}\n"
        fi
	if [[ "${tempLines[i]}" == *" # MXd"* ]]; then
	    echo -e "\ttest:\t${tempLines[i]}\n"
	    tempLines[i]="      5000521 $1 # MXd"
	    echo -e "\ttest:\t${tempLines[i]}\n"
	fi
        if [[ "${tempLines[i]}" == *" # my1"* ]]; then
	    echo -e "\ttest:\t${tempLines[i]}\n"
            tempLines[i]="      5000001 $2 # my1"
	    echo -e "\ttest:\t${tempLines[i]}\n"
        fi
	if [[ "${tempLines[i]}" == *" # MY1"* ]]; then
	    echo -e "\ttest:\t${tempLines[i]}\n"
	    tempLines[i]="      5000001 $2 # MY1"
	    echo -e "\ttest:\t${tempLines[i]}\n"
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
    echo -e "\tInitializing param_card\n"
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

initParamCard

declare -a massx
declare -a massy

echo -e "\tReading masses\n"
while IFS=$'\t' read -r mx my; do
    massx+=($mx)
    massy+=($my)
done < "${mlPath}"

numExistingRuns=$(find "$eventPath" -mindepth 1 -maxdepth 1 -type d | wc -l)

#numExistingRuns=0

runCont=$((numExistingRuns + 1))

if [[ "$numExistingRuns" != 0 ]]; then
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\tThere is $numExistingRuns saved runs\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

echo -e "\tStarting generation\n"

numMassPoint=1
for massIndex in "${!massx[@]}"; do
	cont=1

	while [[ "$cont" -le "$totalRuns" ]]; do
		modRunCard
		wait
	    	modParamCard "${massx[massIndex]}" "${massy[massIndex]}"
		wait
		echo -e "\n\n\t\t\tGenerating Events with mx=${massx[massIndex]} and my=${massy[massIndex]} (Run:${cont}/${totalRuns})\n\n"
    		$binPath gen_events.sh
	    	if [[ $runCont -lt 10 ]]; then
		    	#echo -e "Test: runCont < 10"
		    	rootPath="${eventPath}run_0${runCont}/tag_1_delphes_events.root"
			htmlPath="${htmlDirPath}run_0${runCont}/results.html"
	    	else
		    	rootPath="${eventPath}run_${runCont}/tag_1_delphes_events.root"
			htmlPath="${htmlDirPath}run_${runCont}/results.html"
	    	fi
		runSave=$((cont+offset))
	    	outputPath="${outPath}${mgDir}_${numMassPoint}_${runSave}.csv"
		outputHTMLPath="${outHTMLPath}${mgDir}_${numMassPoint}_${runSave}.html"
	    	echo -e "\tSaving run in CSV\n"
	    	echo -e "\nrootPath='${rootPath}'\noutputPath='${outputPath}'"
	    	python3 -c "import expCSV; expCSV.export_to_csv('${rootPath}','${outputPath}')"
		cp $htmlPath $outputHTMLPath
	    	((runCont++))
		((cont++))
	done
	((numMassPoint++))
done
