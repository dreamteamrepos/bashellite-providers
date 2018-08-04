bashelliteProviderWrapperGit() {
  for line in $(cat ${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf); do
    unset git_repo_alt_dir_name
    IFS=$',\n'
    repo_array=( ${line} )
    unset IFS
    repo_array_size=${#repo_array[@]}
    if [ ${repo_array_size} == 2 ]; then
      git_repo_alt_dir_name=${repo_array[1]}
      line=${repo_array[0]}
      git_repo_dir_name="${git_repo_alt_dir_name}"
    else
      git_repo_name="${line##*/}"
      git_repo_dir_name="${git_repo_name//.git}"
    fi
  
    git_repo_url="${line}"

    if [[ -d "${_r_mirror_tld}/${_n_mirror_repo_name}/${git_repo_dir_name}" ]]; then
      Info "Pulling any updates from repo: ${git_repo_url}..."
      cd "${_r_mirror_tld}/${_n_mirror_repo_name}/${git_repo_dir_name}"
      git pull
    else
      Info "New repo detected, cloning repo: ${git_repo_url}..."
      cd "${_r_mirror_tld}/${_n_mirror_repo_name}"
      Info "Cloning to directory: ${git_repo_dir_name}..."
      git clone "${git_repo_url}" "${git_repo_dir_name}"
    fi
  done
}
