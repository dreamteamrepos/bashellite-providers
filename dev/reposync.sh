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
      # newstr=${oldstr#http*//*/}
      # Parse the directory structure from the baseurl
      save_dir=${repo_base#http*//*/}
      # Check for the existance of the directory structure.  If not existing, create it
      #if [[ ! -d "${save_loc}/${save_dir}" ]]; then
      #  mkdir -p ${save_loc}/${save_dir}
      #fi
      reposync -c ${config_file} -r ${repo_id} -p ${save_loc}/${save_dir} --norepopath -m
    fi
  fi  
done < ${config_file};
