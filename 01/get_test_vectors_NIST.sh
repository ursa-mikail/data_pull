#!/bin/bash
# get_test_vectors_NIST.sh
# Reads GitHub directory links from curl_list.txt
# Uses GitHub API to find actual files, then downloads via raw URLs

INPUT_FILE="curl_list.txt"
OUTPUT_DIR="downloads"

# Create output directory
mkdir -p "$OUTPUT_DIR"

while IFS= read -r url; do
    # Skip empty lines or comments
    [[ -z "$url" || "$url" =~ ^# ]] && continue

    echo "Processing: $url"

    # Parse the GitHub URL
    # Example: https://github.com/usnistgov/ACVP-Server/tree/master/gen-val/json-files/ML-KEM-encapDecap-FIPS203
    owner=$(echo "$url" | cut -d/ -f4)
    repo=$(echo "$url" | cut -d/ -f5)
    branch=$(echo "$url" | cut -d/ -f7)
    path=$(echo "$url" | cut -d/ -f8-)

    echo "  Checking directory: $owner/$repo/$branch/$path"

    # GitHub API endpoint for listing directory contents
    api_url="https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch"

    # Fetch directory contents
    api_response=$(curl -s "$api_url")
    
    # Check if the API response contains an error
    if echo "$api_response" | grep -q '"message":'; then
        echo "  ✗ Directory not found or API error:"
        echo "    $(echo "$api_response" | grep -o '"message":"[^"]*"')"
        continue
    fi

    # Check if response is empty
    if [[ -z "$api_response" || "$api_response" == "null" ]]; then
        echo "  ✗ Empty API response"
        continue
    fi

    # Extract all files (not just JSON) to see what's available
    all_files=$(echo "$api_response" | grep '"name":' | sed 's/.*"name": *"\([^"]*\)".*/\1/')
    
    if [[ -z "$all_files" ]]; then
        echo "  ✗ No files found in directory"
        continue
    fi

    echo "  Available files:"
    echo "$all_files" | sed 's/^/    /'

    # Filter for JSON files
    json_files=$(echo "$all_files" | grep '\.json$')
    
    if [[ -z "$json_files" ]]; then
        echo "  ✗ No JSON files found"
        continue
    fi

    echo "  JSON files to download:"
    echo "$json_files" | sed 's/^/    /'

    # Create local directory
    local_dir="$OUTPUT_DIR/$path"
    mkdir -p "$local_dir"

    # Download each JSON file
    echo "$json_files" | while IFS= read -r json_file; do
        [[ -z "$json_file" ]] && continue
        
        # Construct raw URL
        raw_url="https://raw.githubusercontent.com/$owner/$repo/refs/heads/$branch/$path/$json_file"
        local_path="$local_dir/$json_file"
        
        echo "  Downloading: $json_file"
        
        if curl -sL "$raw_url" -o "$local_path"; then
            if [[ -s "$local_path" ]]; then
                echo "    ✓ Success: $json_file ($(stat -f%z "$local_path" 2>/dev/null || stat -c%s "$local_path" 2>/dev/null) bytes)"
            else
                echo "    ✗ Empty file: $json_file"
                rm -f "$local_path"
            fi
        else
            echo "    ✗ Download failed: $json_file"
            rm -f "$local_path"
        fi
    done

done < "$INPUT_FILE"

echo ""
echo "Download summary:"
find "$OUTPUT_DIR" -name "*.json" -exec echo "✓ {}" \; 2>/dev/null || echo "No files downloaded"