bashelliteProviderWrapper() {

  local basepath_parameter="$(grep -oP "(?<=(^set base_path[[:space:]]*))[[:alnum:]/]*" ${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf)"
  if [[  "${basepath_parameter}" != "${_r_mirror_tld}/${_n_repo_name}" ]]; then
    utilMsg WARN "$(utilTime)" "The \"base_path\" parameter (${basepath_parameter}) in provider.conf does not match mirror location (${_r_mirror_tld}/${_n_repo_name})..."
  fi

  local config_file="${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf"
  local tmp_config_file="${HOME}/.bashellite/tmp_${_n_repo_name}_provider.conf"

  cat /dev/null > ${tmp_config_file}

  IFS=$'\n'
  for line in $(cat ${config_file}); do
    if [[ ${line} =~ ^set[[:blank:]]base_path[[:blank:]]+[[:alnum:]/]+ ]]; then
      echo "set base_path         ${_r_mirror_tld}/${_n_repo_name}" >> ${tmp_config_file}
    else
      echo "${line}" >> ${tmp_config_file}
    fi
  done
  unset IFS

  utilMsg INFO "$(utilTime)" "Proceeding with sync of repo (${_n_repo_name})..."
  # If dryrun is true, perform dryrun
  if [[ ${_r_dryrun} ]]; then
    utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) completed without error..."
  # If dryrun is not true, perform real run
  else
    apt-mirror ${tmp_config_file};
    if [[ "${?}" == "0" ]]; then
      utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) completed without error...";
    else
      utilMsg WARN "$(utilTime)" "Sync of repo (${_n_repo_name}) did NOT complete without error...";
    fi
  fi

}
