bashelliteProviderWrapperWget() {

  # Change IFS so that only newline is word delimiter for provider.conf processing
  IFS=$'\n'
  local filter_array_count=0
  local filter_array=()
  for line in $(cat ${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf); do
    local filter_array[${filter_array_count}]=${line};
    local filter_array_count=$[${filter_array_count}+1]
  done
  unset IFS

  for (( i=0; i<${#filter_array[@]}; i++ )); do
    local line=${filter_array[${i}]}
    # recurse_flag will be set for each line if "r " is at the beginning of the line
    local recurse_flag="";
    if [[ "${line:0:2}" == "r " ]]; then
      local line="${line:2}";
      local recurse_flag="-r -l inf -np";
    fi

    # If provider entry ends in "/" assume it's a directory-include
    if [[ "${line: -1}" == "/" ]]; then
      local wget_include_directory="${line}";
    else
      # Else, assume it's a file-include and parse out just the filename
      local wget_filename="${line##*/}";
      if [[ "${#wget_filename}" != "${#line}" ]]; then
        # If it's both a directory and file-include, parse them out and grab both seperate
        local wget_include_directory="${line%/*}/";
      else
        local wget_include_directory="";
      fi
    fi

    if [[ ${_r_dryrun} ]]; then
      local wget_dryrun_flag="--spider";
    else
      local wget_dryrun_flag="";
    fi

    utilMsg INFO "$(utilTime)" "Attempting to download file(s):"
    utilMsg INFO "$(utilTime)" "  From => ${_n_repo_url}/${line}"
    utilMsg INFO "$(utilTime)" "    To => ${_r_mirror_tld}/${_n_mirror_repo_name}/${line}"
    local wget_args=""
    local wget_args="${wget_dryrun_flag}"
    local wget_args="${wget_args} -nv -nH -e robots=off -N"
    local wget_args="${wget_args} ${recurse_flag}"
    # If we have a non-recursive file specified, don't use the --accept option
    if [[ ${recurse_flag} != "" ]]; then
      local wget_args="${wget_args} --accept "${wget_filename}""
      local wget_args="${wget_args} --reject "index*""
    fi
    local wget_args="${wget_args} -P "${_r_mirror_tld}/${_n_mirror_repo_name}/""
    # If we have a non-recursive file specified, change how we set the url
    if [[ ${recurse_flag} == "" ]]; then
      local wget_args="${wget_args} "${_n_repo_url}/${wget_include_directory}${wget_filename}" "
    else
      local wget_args="${wget_args} "${_n_repo_url}/${wget_include_directory}" "
    fi

    # wget unfortunately sends ALL output to STDERR.
    utilMsg INFO "$(utilTime)" "Running: wget ${wget_args}"
    set -f
    wget ${wget_args} 2>&1 \
    | grep -oP "(?<=(URL: ))http.*(?=(\s*200 OK$))" \
    | while read url; do utilMsg INFO "$(utilTime)" "Downloaded $url"; done
    if [[ "${PIPESTATUS[1]}" == "0" ]]; then
      utilMsg INFO "$(utilTime)" "wget successfully downloaded file(s):"
      utilMsg INFO "$(utilTime)" "  From => ${_n_repo_url}/${line}"
      utilMsg INFO "$(utilTime)" "    To => ${_r_mirror_tld}/${_n_mirror_repo_name}/${line}"
    else
      utilMsg WARN "$(utilTime)" "wget did NOT successfully download file(s):"
      utilMsg WARN "$(utilTime)" "  From => ${_n_repo_url}/${line}"
      utilMsg WARN "$(utilTime)" "    To => ${_r_mirror_tld}/${_n_mirror_repo_name}/${line}"
    fi
    set +f;
  done

}
