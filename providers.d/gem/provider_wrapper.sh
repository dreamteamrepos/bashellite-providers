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

  # Get location of rubygems-mirror gem to use rake
  #local gem_install_dir=$(bundle show rubygems-mirror)
  local gem_install_dir=$(ls "/usr/local/share/gems/gems/")

  # use for loop to go through listing to find rubygems-mirror path

  if [[ -z ${gem_install_dir} ]]; then
    utilMsg INFO "$(utilTime)" "Downloading gems..."
    cd ${gem_install_dir}
    rake mirror:update
  else
    utilMsg FAIL "$(utilTime)" "Unable to find location of rubygems-mirror gem."
  fi

}
