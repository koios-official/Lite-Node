#!/bin/bash

# Get the full path of the current script's directory
script_dir=$(dirname "$(realpath "$BASH_SOURCE")")

# Remove the last folder from the path and rename it to KLITE_HOME
KLITE_HOME=$(dirname "$script_dir")

# Define the line to be appended
path_line="export PATH=\"$script_dir:\$PATH\""

# Function to append path_line if it doesn't already exist in the file
append_if_not_exists() {
    local file=$1
    local line=$2
    if ! grep -Fxq "$line" "$file"; then
        echo "$line" >> "$file"
        # echo "Updated $file with script_dir in PATH."
    # else
    #      echo "$file already contains the path line. No update needed."
    fi
}