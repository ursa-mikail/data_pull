# GitHub JSON Downloader

This project provides a Bash script to **download all JSON files** from specific GitHub directories listed in `curl_list.txt`. The links current comes from e.g. ![list](https://github.com/usnistgov/ACVP-Server/tree/master/gen-val/json-files/ML-DSA-keyGen-FIPS204) 
The script uses the **GitHub API** to list files, constructs the raw download URLs, and mirrors the directory structure locally under a `downloads/` folder.

---

## Features

- Reads a list of GitHub directory URLs from `curl_list.txt`
- Uses the GitHub API to find all `.json` files in each directory
- Downloads all JSON files into a local `downloads/` folder
- Preserves the original GitHub directory structure
- Skips empty lines and comments (`#`) in `curl_list.txt`

---

## Requirements

- A Unix-like environment (Linux, macOS, WSL)
- `curl` installed
- Internet connection

---

## Usage

1. Clone or copy this repository.
2. Add the GitHub directory links to `curl_list.txt` (example below):


