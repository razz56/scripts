#!/bin/bash
BASE="scriptsresponse"

# Color codes
GREEN="\e[32m"   # Domain header
YELLOW="\e[33m"  # JS filename
CYAN="\e[36m"    # Reset ke baad optional
RESET="\e[0m"

for domain in "$BASE"/*; do
    [ -d "$domain" ] || continue
    domname=$(basename "$domain")

    # Domain header in green & bold
    echo -e "\n${GREEN}========== $domname ==========${RESET}"

    for jsfile in "$domain"/*.js; do
        [ -e "$jsfile" ] || continue

        # JS file name in yellow
        echo -e "${YELLOW}--- $(basename "$jsfile") ---${RESET}"

        # LinkFinder output normal color
        python /home/rajrecon/Desktop/tools/LinkFinder/linkfinder.py \
            -i "$jsfile" -o cli
        echo
    done
done
