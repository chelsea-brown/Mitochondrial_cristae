#!/bin/bash

# Check if the filename is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

filename=$1

# Check if the file exists
if [ ! -f "$filename" ]; then
    echo "File not found!"
    exit 1
fi

# Count the number of lines containing 'nan'
count=$(grep -i 'nan' "$filename" | wc -l)

# Remove lines containing 'nan' and update the file
grep -iv 'nan' "$filename" > temp_file && mv temp_file "$filename"

# Display the number of lines removed
echo "Number of lines removed: $count"

