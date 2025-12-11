#!/bin/bash

#
# This script is intended to only run during the docker build process.
#

[[ -x "$SNEWS_MODE" ]] && export SNEWS_MODE="dev"


# Check if the required environment variables are set
if [[ -z "$HOP_USERNAME" || -z "$HOP_PASSWORD" ]]; then
  # If not set, let's try pass
  if [[ "$(type -p pass)" != "" ]]; then
    export HOP_USERNAME=`pass SNEWS/Purdue/${SNEWS_MODE}/hop/username`
    export HOP_PASSWORD=`pass SNEWS/Purdue/${SNEWS_MODE}/hop/password`
  else
    echo "Error: HOP_USERNAME and HOP_PASSWORD environment variables must be set."
    exit 1
  fi
fi

if [[ -z "$POSTGRES_USER" || -z "$POSTGRES_PASSWORD" ]]; then
  # If not set, let's try pass
  if [[ "$(type -p pass)" != "" ]]; then
    export POSTGRES_USER=`pass SNEWS/Purdue/${SNEWS_MODE}/database/username`
    export POSTGRES_PASSWORD=`pass SNEWS/Purdue/${SNEWS_MODE}/database/password`
  else
    echo "Error: POSTGRES_USER and POSTGRES_PASSWORD environment variables must be set."
    exit 1
  fi
fi
# Create the hop_creds.csv file
echo "username,password,hostname" > /app/hop_creds.csv
echo "$HOP_USERNAME,$HOP_PASSWORD,kafka.scimma.org" >> /app/hop_creds.csv

echo "hop_creds.csv file created successfully."
