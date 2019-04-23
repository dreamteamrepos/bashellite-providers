bashelliteProviderWrapperPodman() {

  # Set vars based on passed in vars
  config_file="${_r_metadata_tld}/repos.conf.d/${_n_repo_name}/provider.conf"
  podman_registry_url="${_n_repo_url}"
  mirror_tld="${_r_mirror_tld}"
  mirror_repo_name="${_n_mirror_repo_name}"

  image_name_array=()

  for line in $(cat ${config_file}); do
    # Separating out any username in the repo, otherwise default to a username of 'library'
    IFS=$'/\n'
    repo_line_array=( ${line} )
    unset IFS
    repo_username="library"
    orig_line=${line}
    if [ ${#repo_line_array[@]} == 2 ]; then
        repo_username=${repo_line_array[0]}
        line=${repo_line_array[1]}
    fi

    # Check to see if tags are listed
    tag_index=0
    tag_index=`expr index "${line}" ':'`
    tags_found=""
    tags_found="${line:${tag_index}}"

    if [[ ${tag_index} == 1 || ${tags_found} == "" ]]; then
        utilMsg WARN "$(utilTime)" "Invalid image/tag format found: ${orig_line}, skipping..."
    else
        image_name=""
        if [[ ${tag_index} == 0 ]]; then
            # Didn't find any tags, so setting tag to 'latest'
            utilMsg INFO "$(utilTime)" "Tags not found, using 'latest' tag"
            tags_found="latest"
            image_name=${line}
        else
            # Tags found
            utilMsg INFO "$(utilTime)" "Tags found"
            image_name="${line:0:${tag_index} - 1}"
        fi

        # Create tags array to cycle through
        IFS=$',\n'
        tags_array=( ${tags_found} )
        unset IFS

        # Cycle through each tag, download, and save
        for each_tag in ${tags_array[@]}; do
            repo_image="${podman_registry_url}/${repo_username}/${image_name}:${each_tag}"
            utilMsg INFO "$(utilTime)" "Pulling tag: ${each_tag} for image: ${repo_username}/${image_name}"
            utilMsg INFO "$(utilTime)" "Command: podman pull ${repo_image}"
            if [[ ${dryrun} == "" ]]; then
                #only pull if not a dry run
                podman pull ${repo_image}
            fi

#            # Add image to array for later removal
#            image_name_array+=( "${repo_username}/${image_name}:${each_tag}" )
            save_loc="${mirror_tld}/${mirror_repo_name}"
            image_file_name="${repo_username}-${image_name}-${each_tag}.tar"
            utilMsg INFO "$(utilTime)" "Saving tag: ${each_tag} for image: ${podman_registry_url}/${repo_username}/${image_name}"
            utilMsg INFO "$(utilTime)" "Command: podman save -o ${save_loc}/${image_file_name} ${repo_image}"
            if [[ ${dryrun} == "" ]]; then
                # Only save if not a dry run
                save_file=1
                # Check if file already exists, if it does, check to see if it is current
                if [ -s ${save_loc}/${image_file_name} ]; then
                  # Extract the manifest.json file from the archive to get the Config value
                  tar -x -f ${save_loc}/${image_file_name} --directory=${save_loc} manifest.json
                  file_id=$(cat ${save_loc}/manifest.json | jq .[0].Config | grep -oP "[[:alnum:]]+(?=\.json)")
                  # Next grab the image ID value from podman
                  image_id=$(podman inspect ${repo_image} | jq .[0].Id | grep -oP "(?<=\")[[:alnum:]]+(?=\")")
                  # Remove temporary manifest.json
                  rm -f ${save_loc}/manifest.json
                  # Next compare file_id to image_id, if same skip
                  if [[ ${file_id} == ${image_id} ]]; then
                    utilMsg INFO "$(utilTime)" "Saved image already found, skipping..."
                    save_file=0
                  fi
                fi
                if [[ ${save_file} == 1 ]]; then
                  podman save -o ${save_loc}/${image_file_name} ${repo_image}
                fi
            fi
        done
    fi
  done
#  utilMsg INFO "$(utilTime)" "Removing images pulled to local podman..."
#  for line in ${image_name_array[@]}; do
#    utilMsg INFO "$(utilTime)" "Removing image: ${line} from local podman"
#    utilMsg INFO "$(utilTime)" "Command: podman rmi ${line}"
#    if [[ ${dryrun} == "" ]]; then
#      # Only remove if not a dry run
#      podman rmi ${line}
#    fi
#  done
  unset podman_registry_url;

}
