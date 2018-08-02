bashelliteProviderWrapperGem() {
  local mirror_file="${HOME}/.gem/.mirrorrc"
  utilMsg INFO "$(utilTime)" "Copying config contents to ${HOME}/.gem/.mirrorrc"
  if [[ ! -d "${HOME}/.gem" ]]; then
    mkdir ${HOME}/.gem
  fi
  echo "---" > ${mirror_file}
  echo "- from: ${_n_repo_url}" >> ${mirror_file}
  echo "  to: ${_r_mirror_tld}/${_n_mirror_repo_name}" >> ${mirror_file}
  echo "  parallelism: 10" >> ${mirror_file}
  echo "  retries: 10" >> ${mirror_file}
  echo "  delete: false" >> ${mirror_file}
  echo "  skiperror: true" >> ${mirror_file}
  echo "..." >> ${mirror_file}
  utilMsg INFO "$(utilTime)" "Downloading gems from gem server"

  # use for loop to go through listing to find rubygems-mirror path

  utilMsg INFO "$(utilTime)" "Downloading gems..."
  cd ${_r_providers_tld}/gem/exec/gems/rubygems-mirror*
  rake mirror:update

}
