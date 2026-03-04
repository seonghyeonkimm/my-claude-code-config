#!/bin/bash

# Claude Code Status Line Script
# Provides comprehensive system and project information

# Read JSON input from stdin
input=$(cat)

# Extract information from JSON input
model_name=$(echo "$input" | jq -r '.model.display_name')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
output_style=$(echo "$input" | jq -r '.output_style.name')
version=$(echo "$input" | jq -r '.version')

# Get system information
username=$(whoami)
current_time=$(date '+%H:%M:%S')
current_date=$(date '+%m/%d')

# Abbreviate directory path if too long
if [ ${#current_dir} -gt 40 ]; then
    abbreviated_dir="...${current_dir: -37}"
else
    abbreviated_dir="$current_dir"
fi

# Get git branch if in a git repository
git_branch=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch_name=$(git branch --show-current 2>/dev/null)
    if [ -n "$branch_name" ]; then
        # Check if there are uncommitted changes
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
            git_branch="⎇ $branch_name*"  # asterisk indicates changes
        else
            git_branch="⎇ $branch_name"
        fi
    fi
fi

# Color codes (using printf format)
cyan='\033[36m'
green='\033[32m'
yellow='\033[33m'
blue='\033[34m'
magenta='\033[35m'
red='\033[31m'
bold='\033[1m'
dim='\033[2m'
reset='\033[0m'

# Build the status line with colors
printf "${cyan}${bold}%s${reset}" "$username"
printf " ${dim}@${reset} "
printf "${blue}%s${reset}" "$abbreviated_dir"

if [ -n "$git_branch" ]; then
    printf " ${dim}│${reset} "
    if [[ "$git_branch" == *"*" ]]; then
        printf "${red}%s${reset}" "$git_branch"
    else
        printf "${green}%s${reset}" "$git_branch"
    fi
fi

printf " ${dim}│${reset} "
printf "${yellow}%s${reset}" "$current_time"
printf " ${magenta}%s${reset}" "$current_date"

printf " ${dim}│${reset} "
printf "${bold}%s${reset}" "$model_name"

if [ "$output_style" != "null" ] && [ "$output_style" != "default" ]; then
    printf " ${dim}(%s)${reset}" "$output_style"
fi

echo  # newline at the end