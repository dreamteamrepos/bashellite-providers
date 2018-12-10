#!/bin/bash

config_file=$1

while read line; do
  tmpline=""
  tmpline=$(echo ${line} | grep -oP "(?<=\[)[[:graph:]]+(?=\])")
  if [[ ${tmpline} != "" ]]; then
    echo "Found: ${tmpline}"
  fi
done < ${config_file};
