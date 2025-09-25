#!/bin/bash
# download_all_json.sh
# Reads GitHub directory links from curl_list.txt
# Downloads all *.json files into downloads/, preserving directory structure

INPUT_FILE="curl_list.txt"
OUTPUT_DIR="downloads"

# Create output directory
mkdir -p "$OUTPUT_DIR"

while IFS= read -r url; do
    # Skip empty lines or comments
    [[ -z "$url" || "$url" =~ ^# ]] && continue

    echo "Processing: $url"

    # Example: https://github.com/usnistgov/ACVP-Server/tree/master/gen-val/json-files/ML-KEM-encapDecap-FIPS203
    owner=$(echo "$url" | cut -d/ -f4)
    repo=$(echo "$url" | cut -d/ -f5)
    branch=$(echo "$url" | cut -d/ -f7)
    path=$(echo "$url" | cut -d/ -f8-)

    echo "  Owner: $owner, Repo: $repo, Branch: $branch, Path: $path"

    # GitHub API endpoint for listing directory contents
    api_url="https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch"
    echo "  API URL: $api_url"

    # Fetch JSON list of files in the directory with error handling
    api_response=$(curl -s "$api_url")
    
    # Check if the API response contains an error
    if echo "$api_response" | grep -q '"message":'; then
        echo "  ERROR: API request failed"
        echo "  Response: $api_response"
        continue
    fi

    # Check if response is empty or malformed
    if [[ -z "$api_response" || "$api_response" == "null" ]]; then
        echo "  ERROR: Empty or null API response"
        continue
    fi

    # Extract download URLs for JSON files
    json_urls=$(echo "$api_response" | grep '"download_url":' | grep '\.json"' | cut -d '"' -f4)
    
    if [[ -z "$json_urls" ]]; then
        echo "  WARNING: No JSON files found in this directory"
        # Let's see what files are actually there
        echo "  Available files:"
        echo "$api_response" | grep '"name":' | cut -d '"' -f4 | sed 's/^/    /'
        continue
    fi

    echo "$json_urls" | while read -r raw_url; do
        [[ -z "$raw_url" ]] && continue
        
        # Get the relative path inside repo
        rel_path=$(echo "$raw_url" | sed -E "s#https://raw.githubusercontent.com/$owner/$repo/$branch/##")

        # Construct full local path
        local_path="$OUTPUT_DIR/$rel_path"

        # Create directory structure if needed
        mkdir -p "$(dirname "$local_path")"

        echo "  Downloading $rel_path"
        if ! curl -sL "$raw_url" -o "$local_path"; then
            echo "  ERROR: Failed to download $raw_url"
        fi
    done

done < "$INPUT_FILE"

echo "Download complete. Check the '$OUTPUT_DIR' directory for downloaded files."