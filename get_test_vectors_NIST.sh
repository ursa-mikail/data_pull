#!/bin/bash
# download_all_json.sh
# Reads GitHub directory links from curl_list.txt
# Downloads all *.json files into downloads/, preserving directory structure

INPUT_FILE="curl_list.txt"
OUTPUT_DIR="downloads"

while IFS= read -r url; do
    # Skip empty lines or comments
    [[ -z "$url" || "$url" =~ ^# ]] && continue

    echo "Processing: $url"

    # Example: https://github.com/usnistgov/ACVP-Server/tree/master/gen-val/json-files/ML-KEM-encapDecap-FIPS203
    owner=$(echo "$url" | cut -d/ -f4)
    repo=$(echo "$url" | cut -d/ -f5)
    branch=$(echo "$url" | cut -d/ -f7)
    path=$(echo "$url" | cut -d/ -f8-)

    # GitHub API endpoint for listing directory contents
    api_url="https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch"

    # Fetch JSON list of files in the directory
    curl -s "$api_url" | grep '"download_url":' | grep '\.json"' | cut -d '"' -f4 | while read -r raw_url; do
        # Get the relative path inside repo
        rel_path=$(echo "$raw_url" | sed -E "s#https://raw.githubusercontent.com/$owner/$repo/$branch/##")

        # Construct full local path
        local_path="$OUTPUT_DIR/$rel_path"

        # Create directory structure if needed
        mkdir -p "$(dirname "$local_path")"

        echo "  Downloading $rel_path"
        curl -sL "$raw_url" -o "$local_path"
    done

done < "$INPUT_FILE"
