bashelliteProviderWrapperGoogleRepo() {

  # Check to see if repo has been initialized
  cd ${_r_mirror_tld}/${_n_repo_name}
  if [ ! -d ".repo" ]; then
    # Need to initialize repo
    utilMsg INFO "$(utilTime)" "Repo not initialized.  Initializing..."
    ${_r_providers_tld}/google-repo/exec/repo init -u ${_n_repo_url} --mirror
  fi

  # Repo has been initialized, now ready to sync
  utilMsg INFO "$(utilTime)" "Proceeding with sync of repo (${_n_repo_name})..."
  # If dryrun is true, perform dryrun
  if [[ ${_r_dryrun} ]]; then
    utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) completed without error..."
  # If dryrun is not true, perform real run
  else
    ${_r_providers_tld}/google-repo/exec/repo sync;
    if [[ "${?}" == "0" ]]; then
      utilMsg INFO "$(utilTime)" "Sync of repo (${_n_repo_name}) completed without error...";
    else
      utilMsg WARN "$(utilTime)" "Sync of repo (${_n_repo_name}) did NOT complete without error...";
    fi
  fi

}
