bashelliteProviderWrapperReposync() {

  utilMsg INFO "$(utilTime)" "Proceeding with sync of repo site (${_n_repo_name}) using ${_n_repo_provider}..."

  local config_file="${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf"
  local save_loc="${_r_mirror_tld}/${_n_mirror_repo_name}"

  while read line; do
    local repo_id=""
    repo_id=$(echo ${line} | grep -oP "(?<=\[)[[:graph:]]+(?=\])")
    if [[ ${repo_id} != "" ]]; then
      local repo_base=$(crudini --get ${config_file} ${repo_id} baseurl)
      local repo_enabled=$(crudini --get ${config_file} ${repo_id} enabled)
      if [[ ${repo_enabled} == 1 ]]; then
        utilMsg INFO "$(utilTime)" "Syncing repo: ${repo_id}"
        # newstr=${oldstr#http*//*/}
        # Parse the directory structure from the baseurl
        local save_dir=${repo_base#http*//*/}
        reposync -c ${config_file} -r ${repo_id} -p ${save_loc}/${save_dir} --norepopath --downloadcomps --download-metadata
        local return_val="${?}"
        if [[ "${return_val}" == "0" ]]; then
          createrepo -v --update ${save_loc}/${save_dir}/
          utilMsg INFO "$(utilTime)" "Sync of repo ${repo_id} from repo site (${_n_repo_name}) using ${_n_repo_provider} completed without error...";
        else
          utilMsg WARN "$(utilTime)" "Sync of repo ${repo_id} from repo site (${_n_repo_name}) using ${_n_repo_provider} did NOT complete without error...";
        fi
      fi
    fi  
  done < ${config_file};

}
