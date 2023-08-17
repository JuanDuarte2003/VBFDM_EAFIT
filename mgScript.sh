#!/bin/bash

# paths
rcPath='./MadGraph/MG5_aMC_v3_5_1/projectTest/Cards/run_card.dat'
pcPath='./MadGraph/MG5_aMC_v3_5_1/projectTest/Cards/param_card.dat'
mlPath='./massList.txt'
binPath='./MadGraph/MG5_aMC_v3_5_1/projectTest/bin/generate_events'

# create the mass list
chmod u+x massListGenerator.sh
./massListGenerator.sh

# Initial parameters for the param_card
declare -A couplingDic=(
    [gsxr]="      1 0.000000e+00"
    [gsxc]="      2 0.000000e+00"
    [gsxd]="      3 0.000000e+00"
    [gpxd]="      4 0.000000e+00"
    [gsd11]="      5 0.000000e+00"
    [gsu11]="      6 0.000000e+00"
    [gsd22]="      7 0.000000e+00"
    [gsu22]="      8 0.000000e+00"
    [gsd33]="      9 0.000000e+00"
    [gsu33]="      10 0.000000e+00"
    [gpd11]="      11 0.000000e+00"
    [gpu11]="      12 0.000000e+00"
    [gpd22]="      13 0.000000e+00"
    [gpu22]="      14 0.000000e+00"
    [gpd33]="      15 0.000000e+00"
    [gpu33]="      16 0.000000e+00"
    [lambda]="      17 1.000000e+05"
    [gsg]="      18 1.000000e+00"
    [gpg]="      19 0.000000e+00"
    [gsh1]="      20 0.000000e+00"
    [gsh2]="      21 0.000000e+00"
    [gsb]="      22 0.000000e+00"
    [gpb]="      23 0.000000e+00"
    [gsw]="      24 0.000000e+00"
    [gpw]="      25 0.000000e+00"
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
        if [[ "${tempLines[i]}" == *" # mxd"* ]]; then
            tempLines[i]="      52 $1 # mxd"
        fi
        if [[ "${tempLines[i]}" == *" # my0"* ]]; then
            tempLines[i]="      54 $2 # my0"
        fi
    done

    rm $pcPath

    for line in "${tempLines[@]}"; do
        echo "${line}" >> "$pcPath"
    done

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
    echo -e "\n\n\n\t\t\tGenerating Events with mx=${massx[massIndex]} and my=${massy[massIndex]}\n\n\n"
    $binPath -f
done
