#!/bin/bash

config_file=$1

while read line; do
  repo_id=""
  repo_id=$(echo ${line} | grep -oP "(?<=\[)[[:graph:]]+(?=\])")
  if [[ ${repo_id} != "" ]]; then
    echo "Found: ${repo_id}"
  fi
done < ${config_file};
