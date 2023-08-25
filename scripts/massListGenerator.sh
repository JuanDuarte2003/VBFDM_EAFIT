#!/bin/bash

# mass lists
mx=(10.0)
my=(100.0)

# file path
fpath='./massList.txt'

# Create or overwrite the file
#echo -e "mx\tmy" > "$fpath"
rm "$fpath"

# Loop to input data
for x in "${mx[@]}"; do
    for y in "${my[@]}"; do
	if (( $(python -c "print(int($x * 2 <= $y))"))); then
            echo -e "${x}\t${y}" >> "$fpath"
        fi
    done
done
