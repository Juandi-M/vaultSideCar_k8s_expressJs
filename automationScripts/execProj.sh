#!/bin/bash

# Script Name: execProj.sh
# Author: Juan Monge
# Description: Execute the whole project onece

LOG_FILE="./script_execution.log"
echo "Logging to $LOG_FILE"
echo "Script started at $(date)" > "$LOG_FILE"

# Function to handle errors
handle_error() {
  local line_number=$1
  local exit_status=$2
  echo -e "\e[31mError occurred in script at line: $line_number.\e[0m" # Print error message in red
  echo "Line exited with status: $exit_status"
  echo "Error at $(date). Check $LOG_FILE for more details." >> "$LOG_FILE" # Log error details to log file
  exit "$exit_status" # Exit the script with the provided exit status
}

# Function to run a script
run_script() {
  local script_name=$1
  echo -e "\e[34mRunning $script_name...\e[0m" # Print script name in blue
  echo "Running $script_name at $(date)" >> "$LOG_FILE" # Log script execution start time
  
  if [ "$script_name" == "ClusterOps.sh" ]; then
    echo "r" | ./"$script_name" >> "$LOG_FILE" 2>&1 # Run script and redirect output to log file
  elif [ "$script_name" == "helm/deployVaultHelm.sh" ]; then
    echo "2" | ./"$script_name" >> "$LOG_FILE" 2>&1 # Run script and redirect output to log file
  else
    ./"$script_name" >> "$LOG_FILE" 2>&1 # Run script and redirect output to log file
  fi
  
  local exit_code=$? # Get the exit code of the script
  
  if [ "$exit_code" -ne 0 ]; then
    handle_error "$LINENO" "$exit_code" # Call handle_error function if script exits with non-zero status
  else
    echo -e "\e[32m$script_name completed successfully.\e[0m" # Print success message in green
    echo "$script_name completed successfully at $(date)" >> "$LOG_FILE" # Log script completion time
  fi
}

read -p "Do you want to execute the scripts? (y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Exiting."
  exit 1
fi

run_script "ClusterOps.sh" # Run ClusterOps.sh script
run_script "configure-vault-auth-and-roles.sh" # Run configure-vault-auth-and-roles.sh script
run_script "deploy-vault-helm.sh" # Run helm/deploy-vault-helm.sh script

echo "All selected scripts ran successfully."
echo "Script ended at $(date)" >> "$LOG_FILE" # Log script end time