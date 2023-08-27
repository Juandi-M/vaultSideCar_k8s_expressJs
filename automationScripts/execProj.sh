#!/bin/bash

# Script Information
# ------------------
# Script Name: execProj.sh
# Author: Juan Monge
# Description: This script executes the entire project at once.

# Define where we'll store the log of what happens
LOG_FILE="./script_execution.log"
echo "We are logging what happens to $LOG_FILE"

# Write the start time to the log
echo "Script started at $(date)" > "$LOG_FILE"

# Function to Handle Errors
# -------------------------
# If something goes wrong, this function will run.
handle_error() {
  echo "Oops! Something went wrong. Check $LOG_FILE for details."
  echo "Error at $(date). Check $LOG_FILE for more details." >> "$LOG_FILE"
  exit 1
}

# Function to Run a Script
# ------------------------
# This function runs a given script and logs what happens.
run_script() {
  local script_name=$1  # The name of the script to run
  echo "Now running $script_name..."
  echo "Running $script_name at $(date)" >> "$LOG_FILE"

  # Run the script and save any messages or errors to the log file
  if [ "$script_name" == "ClusterOps.sh" ]; then
    echo "r" | ./"$script_name" >> "$LOG_FILE" 2>&1 || handle_error
  elif [ "$script_name" == "deployVaultHelm.sh" ]; then
    echo "2" | ./"$script_name" >> "$LOG_FILE" 2>&1 || handle_error
  else
    ./"$script_name" >> "$LOG_FILE" 2>&1 || handle_error
  fi

  echo "$script_name completed successfully at $(date)" >> "$LOG_FILE"
}

# Ask if the user is sure about running the scripts
read -p "Do you want to execute the scripts? (y/n): " -n 1 -r
echo  # Move to a new line

# If the user says anything other than 'y', stop right there!
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "You chose not to run the scripts. Exiting."
  exit 1
fi

# Run each script one by one
run_script "ClusterOps.sh"
run_script "configure-vault-auth-and-roles.sh"
run_script "deployVaultHelm.sh"

# Yay, we made it to the end!
echo "All scripts ran successfully!"
echo "Script ended at $(date)" >> "$LOG_FILE"