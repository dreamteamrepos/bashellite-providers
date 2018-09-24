bashelliteProviderWrapper() {

  local basepath_parameter=$(egrep "^\s*set\s*base_path\s*[[:alnum:]/_-.]*" "${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf")
  basepath_parameter="${basepath_parameter#*set*base_path}"
  if [[  "${basepath_parameter}" != "${_r_mirror_tld}/${_n_repo_name}" ]]; then
    utilMsg WARN "$(utilTime)" "The \"base_path\" parameter ("${basepath_parameter}") in provider.conf does not match mirror location (${_r_mirror_tld}/${_n_repo_name})..."
  fi

  local config_file="${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf"
  local tmp_config_file="${HOME}/.bashellite/tmp_${_n_repo_name}_provider.conf"

  > ${tmp_config_file}

  local line_counter=0
  while IFS=$'\n' read line; do
    if [[ "${line}" =~ ^set[[:blank:]]base_path[[:blank:]]+[[:alnum:]/_-.]+ ]]; then
      if [ "${line_counter}" = 0 ]; then
        echo "set base_path         ${_r_mirror_tld}/${_n_repo_name}" >> ${tmp_config_file}
      else
        utilMsg WARN "$(utilTime)" "Duplicate base_path parameter found.  Skipping line..."
      fi
      line_counter=$(($line_counter + 1))
    else
      echo "${line}" >> ${tmp_config_file}
    fi
  done < ${config_file}

  utilMsg INFO "$(utilTime)" "Proceeding with sync of repo (${_n_repo_name}) using ${_n_repo_provider}..."
  # If dryrun is true, perform dryrun
  if [[ ${_r_dryrun} ]]; then
    utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) using ${_n_repo_provider} completed without error..."
  # If dryrun is not true, perform real run
  else
    apt-mirror ${tmp_config_file};
    if [[ "${?}" == "0" ]]; then
      utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) using ${_n_repo_provider} completed without error...";
    else
      utilMsg WARN "$(utilTime)" "Sync of repo (${_n_repo_name}) using ${_n_repo_provider} did NOT complete without error...";
    fi
  fi

}
