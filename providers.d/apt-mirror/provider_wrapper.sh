bashelliteProviderWrapper() {

  local temp_config_file="/tmp/bashellite_tmp_${_n_repo_name}_config.conf"
  local provider_config_file="${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf"

  if [[ ! ${_r_dryrun} ]]; then
    echo "set base_path         ${_r_mirror_tld}/${_n_mirror_repo_name}" > ${temp_config_file};
    cat ${provider_config_file} >> ${temp_config_file};
    apt-mirror ${temp_config_file};
  fi

  if [[ "${?}" != "0" ]]; then
    utilMsg WARN "$(utilTime)" "apt-mirror either failed or completed with errors for repo (${_n_repo_name})."
  else
    utilMsg INFO "$(utilTime)" "apt-mirror completed successfully for repo (${_n_repo_name})."
  fi

}
