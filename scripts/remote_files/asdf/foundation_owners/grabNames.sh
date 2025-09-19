#!/bin/bash

# Output file
OUTPUT_FILE="folders.txt"

# Clear file if it already exists
> "$OUTPUT_FILE"

# Loop through directories in current path
for dir in */; do
    if [ -d "$dir" ]; then
        echo "${dir%/}" >> "$OUTPUT_FILE"
    fi
done

echo "All folder names written to $OUTPUT_FILE"

