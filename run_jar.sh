#!/bin/bash

# Check if the directory is provided as an argument
if [ $# -lt 2 ]; then
  echo "Error: Directory not provided"
  exit 1
fi

# Set the directory variable
DIRECTORY=$1
RESULT_FILE=$2

# Set the default value for the optional third argument
REPORT_TYPE="-json -jsonfile"

# Check if the optional third argument is provided
if [ $# -eq 3 ]; then
  REPORT_TYPE=$3
fi

# Set the JAR file path
JAR_FILE="./CFLint-1.5.0-all.jar"

# Run the JAR file with the directory as an argument
java -jar "$JAR_FILE" -file "$DIRECTORY" -q -e "$REPORT_TYPE" "$RESULT_FILE"