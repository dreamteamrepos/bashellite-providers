bashelliteProviderWrapperGem() {
  local ruby_ver="2.5.1"
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

  # Check for installed dependent gems required for mirroring

  utilMsg INFO "$(utilTime)" "Checking for required gems for mirroring..."
  local gem_bin=${HOME}/.rubies/ruby-${ruby_ver}/bin/gem
  local gemlist=$(${gem_bin} list)
  for gem in \
      hoe \
      net-http-persistent \
      rubygems-mirror \
      ; do
    if [[ "${gemlist}" != *"${gem}"* ]]; then 
      utilMsg WARN "$(utilTime)" "${gem} gem dependency not found.  Installing..."
      ${gem_bin} install ${gem}
      gemlist=$(${gem_bin} list)
      if [[ "${gemlist}" == *"${gem}"* ]]; then
        utilMsg INFO "$(utilTime)" "Gem ${gem} installed successfully..."
      else
        utilMsg FAIL "$(utilTime)" "Required gem ${gem} was NOT installed successfully; exiting." \
        && exit 1;
      fi
    else
      utilMsg INFO "$(utilTime)" "Required gem ${gem} already installed..."
    fi 
  done

  utilMsg INFO "$(utilTime)" "Downloading gems from gem server..."
  ${gem_bin} mirror

}
