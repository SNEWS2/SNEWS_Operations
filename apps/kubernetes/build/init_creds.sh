#!/usr/bin/env bash
#
# $Id$
#


[[ -x "$SNEWS_MODE" ]] && export SNEWS_MODE="dev"
[[ -x "$SNEWS_ROLE" ]] && export SNEWS_ROLE="hop"
#
# Ideally, there can be multiple SNEWS_ROLEs - how to best handle this?
#

if [[ "$SNEWS_ROLE"x == "hop"x ]]; then
  if [[ ! -e "~/.config/hop/auth.toml" ]]; then
   HOPUSER=`pass SNEWS/Purdue/${SNEWS_MODE}/hop/username`
   HOPPASS=`pass SNEWS/Purdue/${SNEWS_MODE}/hop/password`
   if [[ ! -z "$HOPUSER" || ! -z "$HOPPASS" ]]; then
     echo "username,password,hostname" > /app/hop_creds.csv
     echo "$HOPUSER,$HOPPASS,kafka.scimma.org" >> /app/hop_creds.csv
     poetry run hop auth add /app/hop_creds.csv && rm -f /app/hop_creds.csv 
   elif [[ -e hop_creds.csv ]]; then
     poetry run hop auth add /app/hop_creds.csv && rm -f /app/hop_creds.csv
   else
     echo "Hop credentials are not setup and hop_creds.csv missing! I am unable to setup hop credentials!"
     exit 1
   fi
  fi
fi

export POSTGRES_USER=`pass SNEWS/Purdue/${SNEWS_MODE}/database/username`
export POSTGRES_PASSWORD=`pass SNEWS/Purdue/${SNEWS_MODE}/database/password`

if [ $# -gt 0 ]; then 
  bash -c "$@"
  wait
fi

