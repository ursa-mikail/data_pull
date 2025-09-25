#!/bin/bash
# get_test_vectors_NIST.sh
# Reads GitHub directory links from curl_list.txt
# Converts them to raw URLs and downloads all *.json files

INPUT_FILE="curl_list.txt"
OUTPUT_DIR="downloads"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Common JSON filenames found in NIST ACVP directories
JSON_FILES=(
    "expectedResults.json"
    "internalProjection.json" 
    "prompt.json"
    "registration.json"
    "validation.json"
)

while IFS= read -r url; do
    # Skip empty lines or comments
    [[ -z "$url" || "$url" =~ ^# ]] && continue

    echo "Processing: $url"

    # Convert GitHub tree URL to raw URL base
    # From: https://github.com/usnistgov/ACVP-Server/tree/master/gen-val/json-files/ML-KEM-encapDecap-FIPS203
    # To:   https://raw.githubusercontent.com/usnistgov/ACVP-Server/refs/heads/master/gen-val/json-files/ML-KEM-encapDecap-FIPS203/
    
    raw_base=$(echo "$url" | sed 's|github\.com|raw.githubusercontent.com|' | sed 's|/tree/|/refs/heads/|')
    
    echo "  Raw base URL: $raw_base"

    # Extract path for local directory structure
    path=$(echo "$url" | cut -d/ -f8-)
    local_dir="$OUTPUT_DIR/$path"
    mkdir -p "$local_dir"

    # Try to download each common JSON file
    for json_file in "${JSON_FILES[@]}"; do
        raw_url="$raw_base/$json_file"
        local_path="$local_dir/$json_file"
        
        echo "  Trying: $json_file"
        
        # Download with curl, suppressing output but checking return code
        if curl -sL "$raw_url" -o "$local_path"; then
            # Check if file actually contains content (not a 404 page)
            if [[ -s "$local_path" ]] && ! grep -q "404: Not Found" "$local_path" 2>/dev/null; then
                echo "    ✓ Downloaded $json_file"
            else
                echo "    ✗ File not found: $json_file"
                rm -f "$local_path"
            fi
        else
            echo "    ✗ Failed to download: $json_file"
            rm -f "$local_path"
        fi
    done

done < "$INPUT_FILE"

echo "Download complete. Check the '$OUTPUT_DIR' directory for downloaded files."