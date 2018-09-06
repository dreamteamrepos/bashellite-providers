bashelliteProviderWrapperGit() {
  for line in $(cat ${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf); do
    local git_repo_alt_dir_name
    local repo_array
    local repo_array_size
    local git_repo_dir_name
    local git_repo_name
    local git_repo_url
    local git_sub_dirs
    IFS=$',\n'
    repo_array=( ${line} )
    unset IFS
    repo_array_size=${#repo_array[@]}
    if [ ${repo_array_size} == 2 ]; then
      git_repo_alt_dir_name=${repo_array[1]}
      line=${repo_array[0]}
      git_repo_dir_name="${git_repo_alt_dir_name%.git}"
    else
      git_repo_name="${line##*/}"
      git_repo_dir_name="${git_repo_name%.git}"
    fi
  
    git_repo_url="${line%.git}"

    # Here we make any subdirectories that need to be made
    git_sub_dirs="${line%/*}"
    if [[ ! -d "${_r_mirror_tld}/${_n_mirror_repo_name}/${git_sub_dirs}" ]]; then
      mkdir -p "${_r_mirror_tld}/${_n_mirror_repo_name}/${git_sub_dirs}"
    fi

    if [[ -d "${_r_mirror_tld}/${_n_mirror_repo_name}/${git_sub_dirs}/${git_repo_dir_name}.git" ]]; then
      utilMsg INFO "$(utilTime)" "Pulling any updates from repo: ${git_repo_url}..."
      cd "${_r_mirror_tld}/${_n_mirror_repo_name}/${git_sub_dirs}/${git_repo_dir_name}.git"
      git fetch
    else
      utilMsg INFO "$(utilTime)" "New repo detected, cloning repo: ${git_repo_url}..."
      cd "${_r_mirror_tld}/${_n_mirror_repo_name}/${git_sub_dirs}"
      utilMsg INFO "$(utilTime)" "Cloning to directory: ${git_repo_dir_name}..."
      git clone --bare "${_n_repo_url}/${git_repo_url}" "${git_repo_dir_name}.git"
    fi
  done
}
