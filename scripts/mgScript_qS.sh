#!/bin/bash

# paths
rcPath='../MadGraph/MG5_aMC_v3_5_1/ppTOy0jj_y0TOxdxd_gSq_rest/Cards/run_card.dat'
pcPath='../MadGraph/MG5_aMC_v3_5_1/ppTOy0jj_y0TOxdxd_gSq_rest/Cards/param_card.dat'
mlPath='./massList.txt'
binPath='../MadGraph/MG5_aMC_v3_5_1/ppTOy0jj_y0TOxdxd_gSq_rest/bin/generate_events'
logPath='../registers/'

# create the mass list
chmod u+x massListGenerator.sh
./massListGenerator.sh

# Initial parameters for the param_card
declare -A couplingDic=(
    [gSxd]="      1 1.000000e+00"
    [gSd11]="      2 1.000000e+00"
    [gSu11]="      3 1.000000e+00"
    [gSd22]="      4 1.000000e+00"
    [gSu22]="      5 1.000000e+00"
    [gSd33]="      6 1.000000e+00"
    [gSu33]="      7 1.000000e+00"
    [Lambda]="      8 1.000000e+04"
    [gSg1]="      9 0.000000e+00"
    [gSg2]="      10 0.000000e+00"
    [gSh1]="      11 0.000000e+00"
    [gSh2]="      12 0.000000e+00"
    [gSh3]="      13 0.000000e+00"
    [gSb]="      14 0.000000e+00"
    [gSw]="      15 0.000000e+00"
)

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

modParamCard () {
    # modifica la param_card ($1 -> mx, $2 -> my)
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
    # Inicializa los parametros de la param_card
    tempPath='temp.dat'
    cp $pcPath $tempPath
    declare -a tempLines
    mapfile -t tempLines < $tempPath

    for i in "${!tempLines[@]}"; do
        for key in "${!couplingDic[@]}"; do
            if [[ "${tempLines[i]}" == *"${key}"* ]]; then
                tempLines[i]="${couplingDic[$key]} # ${key}"
            fi
        done
    done

    rm $pcPath

    for line in "${tempLines[@]}"; do
        echo "${line}" >> "$pcPath"
    done

    rm $tempPath
}

initParamCard

declare -a massx
declare -a massy

while IFS=$'\t' read -r mx my; do
    massx+=($mx)
    massy+=($my)
done < "${mlPath}"

for massIndex in "${!massx[@]}"; do
    modRunCard
    modParamCard "${massx[massIndex]}" "${massy[massIndex]}"
    echo -e "\n\n\t\tGenerating Events with mx=${massx[massIndex]} and my=${massy[massIndex]}\n\n"
    $binPath -f
done
