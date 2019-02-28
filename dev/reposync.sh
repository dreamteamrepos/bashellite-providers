#!/bin/bash

config_file=$1
save_loc=$2

while read line; do
  repo_id=""
  repo_id=$(echo ${line} | grep -oP "(?<=\[)[[:graph:]]+(?=\])")
  if [[ ${repo_id} != "" ]]; then
    repo_base=$(crudini --get ${config_file} ${repo_id} baseurl)
    repo_enabled=$(crudini --get ${config_file} ${repo_id} enabled)
    echo "Base: ${repo_base}"
    if [[ ${repo_enabled} == 1 ]]; then
      echo "Syncing repo: ${repo_id}"
      reposync -c ${config_file} -r ${repo_id} -p ${save_loc}/${repo_id} --norepopath -m

      # newstr=${oldstr#http*//*/}

    fi
  fi  
done < ${config_file};
