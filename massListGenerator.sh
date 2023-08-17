#!/bin/bash

# mass lists
mx=(10.0 50.0 100.0 200.0 400.0 600.0 800.0 1000.0)
my=(100.0 200.0 500.0 800.0 1000.0 2000.0 3000.0 4000.0 5000.0)

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
