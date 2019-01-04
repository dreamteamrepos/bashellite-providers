#!/bin/bash

utilDeps() {

  # Ensures the dependency checker is actually installed before proceeding
  which which &>/dev/null \
    || { echo "[FAIL] Dependency (which) missing!" >&2; return 1; };
  
  # Sanitizes input to a set of reasonable filename characters
  local requested_function_input="${1}";
  local function_input="${requested_function_input//[^A-Za-z0-9_.-]}";
  if [[ "${requested_function_input}" != "${function_input}" ]]; then
    echo "[FAIL] Requested dependency or array name contains invalid characters; exiting." >&2;
    return 1;
  fi
 
  # Determines if $1 is a single dep or an array name by parsing the output of "declare -p"
  local input_type="$(declare -p "${function_input}" 2>/dev/null || echo "non_array" )";
  local input_type="${input_type%%=*}";
  local input_type="${input_type##declare -}";
  case "${input_type:0:1}" in
    a)
      local input_type="array";
      ;;
    *)
      local input_type="dep_name";
      ;;
  esac

  # Populates dep_array with either single dep name or contents of the provided array
  if [[ "${input_type}" == "array" ]]; then
    local dep_array=( $(eval echo \$\{${function_input}\[\@\]\}) );
  else
    local dep_array=( ${function_input} );
  fi

  # Performs path check on all deps listed in dep_array
  for dep in ${dep_array[@]}; do
    which ${dep} &>/dev/null \
      || { echo "[FAIL] Dependency (${dep}) missing!" >&2; return 1; };
  done

}

utilGNU() {

  # Sanitizes input to a set of reasonable filename characters
  local requested_function_input="${1}";
  local function_input="${requested_function_input//[^A-Za-z0-9_.-]}";
  if [[ "${requested_function_input}" != "${function_input}" ]]; then
    echo "[FAIL] Requested GNU dependency or array name contains invalid characters; exiting." >&2;
    return 1;
  fi
 
  # Determines if $1 is a single dep or an array name by parsing the output of "declare -p"
  local input_type="$(declare -p "${function_input}" 2>/dev/null || echo "non_array" )";
  local input_type="${input_type%%=*}";
  local input_type="${input_type##declare -}";
  case "${input_type:0:1}" in
    a)
      local input_type="array";
      ;;
    *)
      local input_type="dep_name";
      ;;
  esac

  # Populates dep_array with either single dep name or contents of the provided array
  if [[ "${input_type}" == "array" ]]; then
    local dep_array=( $(eval echo \$\{${function_input}\[\@\]\}) );
  else
    local dep_array=( ${function_input} );
  fi

  # Performs path check on all deps listed in dep_array
  for dep in ${dep_array[@]}; do
    ${dep} --version 2>&1 \
    | { \
         read -r line;
         parsed_line="${line//*GNU*/GNU}";
         if [[ "${parsed_line}" != "GNU" ]]; then
           echo "[FAIL] Dependency (${dep}) not GNU version!" >&2;
           return 1;
         fi;
      };
  done

}

utilTime() {

  # Check to ensure the date binary is present in path, and the GNU version
  utilDeps date;
  utilGNU date;

  local timestamp="$(date --iso-8601='ns' 2>/dev/null)";
  local timestamp="${timestamp//[^0-9]}";
  local timestamp="${timestamp:8:8}";
  if [[ -z "${timestamp}" ]]; then
    echo "[FAIL] Failed to set timestamp; ensure date supports \"--iso-8601\" flag!" >&2;
    return 1;
  else
    echo "${timestamp}";
  fi

}

utilMsg() {

  # Ensure locale is set to default to ensure bash pattern-matching works as expected  
  local LC_COLLATE="C";

  # Ensures there are at least three parameters passed in before continuing
  if [[ "${#}" -lt "3" ]]; then
    echo "[FAIL] Failed to pass in minimum number of required parameters to function (${FUNCNAME[0]}); exiting." >&2;
    return 2;
  fi
  
  # Parses and sanitizes the msg_type parameter passed to function
  local requested_msg_type="${1}";
  local msg_type="${requested_msg_type//[^A-Z]}";
  if [[ "${requested_msg_type}" != "${msg_type}" ]]; then
    echo "[FAIL] Requested message type (${requested_msg_type}) passed to function (${FUNCNAME[0]}) contains invalid characters; exiting."
    return 2;
  fi
  shift;

  # Parses and sanitizes the timestamp parameter passed to function
  local requested_timestamp="${1}";
  local timestamp="${requested_timestamp//[^A-Za-z0-9 ,:._-]}";
  if [[ "${requested_timestamp}" != "${timestamp}" ]]; then
    echo "[FAIL] Requested timestamp (${requested_timestamp}) passed to function (${FUNCNAME[0]}) contains invalid characters; exiting."
    return 2;
  fi
  shift;
  
  # Sets up color coding provided by parent program
  case ${msg_type} in
    FAIL|WARN|INFO|SKIP)
      case ${msg_type} in
         FAIL)
           local msg_color="${PROG_MSG_RED}";
           local error_msg="true";
           ;;
         WARN)
           local msg_color="${PROG_MSG_YELLOW}";
           local error_msg="true";
           ;;
         INFO)
           local msg_color="${PROG_MSG_GREEN}";
           ;;
         SKIP)
           local msg_color="${PROG_MSG_BLUE}";
           ;;
      esac
      local opener="[";
      local closer="]";
      if [[ ${_r_dryrun} ]]; then
        local dryrun_tag="DRYRUN|";
      fi
      ;;
    RED|YELLOW|GREEN|BLUE)
      case ${msg_type} in
         RED)
           local msg_color="${PROG_MSG_RED}";
           local error_msg="true";
           ;;
         YELLOW)
           local msg_color="${PROG_MSG_YELLOW}";
           local error_msg="true";
           ;;
         GREEN)
           local msg_color="${PROG_MSG_GREEN}";
           ;;
         BLUE)
           local msg_color="${PROG_MSG_BLUE}";
           ;;
      esac
      local msg_type="    ";
      local opener=" ";
      local closer=" ";
      if [[ ${_r_dryrun} ]]; then
        local dryrun_tag="       ";
      fi
      local timestamp="$(eval printf \' %.0s\' {1..${#timestamp}})";
      ;;
    *)
      echo "[FAIL] The passed parameter (${msg_type}) is not a valid message type; exiting." >&2;
      return 2;
      ;;
  esac

  # Prints ${3} and beyond as the message; ${1} is the type; ${2} is the timestamp
  if [[ "${error_msg}" == "true" ]]; then
    # If message is an error message, send to STDERR
    echo -e "${PROG_MSG_WHITE}${timestamp} ${msg_color}${opener}${dryrun_tag}${msg_type}${closer} $*${PROG_MSG_CLEAR}" >&2;
    # If the error is indicating an exit-worthy failure, exit program after printing error message
    if [[ "${msg_type}" == "FAIL" ]]; then
      return 1;
    fi
  else
    echo -e "${PROG_MSG_WHITE}${timestamp} ${msg_color}${opener}${dryrun_tag}${msg_type}${closer} $*${PROG_MSG_CLEAR}" >&1;
  fi
  
}

# This function prints usage messaging to STDOUT when invoked.
Usage() {
  echo
  echo "Usage: $(basename ${0}) v${script_version}"
  echo "       [-m mirror_top-level_directory]"
  echo "       [-h]"
  echo "       [-d]"
  echo "       [-r repository_name]"
  echo
  echo
  echo "       Required Parameter(s):"
  echo "       -m:  Sets a temporary disk mirror top-level directory."
  echo "            Only absolute (full) paths are accepted!"
  echo "       -r:  The repo name to sync."
  echo "       -c:  The config file that has the filter of images to download"
  echo "       Optional Parameter(s):"
  echo "       -h:  Prints this usage message."
  echo "       -d:  Dry-run mode. Pulls down a listing of the files and"
  echo "            directories it would download, and then exits."
  echo "       -s:  An optional site name to pull images from.  Default is: docker.io"
}

# This function parses the parameters passed over the command-line by the user.
Parse_parameters() {
  if [[ "${#}" = "0" ]]; then
    Usage;
    utilMsg FAIL "$(utilTime)" "${0} has mandatory parameters; review usage message and try again.";
  fi

  # Bash-builtin getopts is used to perform parsing, so no long options are used.
  while getopts ":m:r:c:s:hd" passed_parameter; do
   case "${passed_parameter}" in
      m)
        mirror_tld="${OPTARG}";
        ;;
      r)
        # Sanitizes the directory name of spaces or any other undesired characters.
	      mirror_repo_name="${OPTARG//[^a-zA-Z1-9_-]}";
	      ;;
      d)
        dryrun=true;
        ;;
      c)
        config_file="${OPTARG}";
        ;;
      s)
        podman_registry_url="${OPTARG}";
        ;;
      h)
        Usage;
        exit 0;
        ;;
      *)
        Usage;
        utilMsg FAIL "$(utilTime)" "Invalid option passed to \"$(basename ${0})\"; exiting. See Usage below.";
        ;;
    esac
  done
  shift $((OPTIND-1));
}

  # Set vars based on passed in vars
  config_file="test.conf"
  podman_registry_url="docker.io"
  mirror_tld="/home/chandler/test"
  mirror_repo_name="podman"

  Parse_parameters ${@}

#if [[ ${?} == 0 ]]; then

if [[ $(Parse_parameters ${@}) == 0 ]]; then

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

        # podman inspect gns3/webterm | jq .[0].Id | grep -oP "(?<=\")[[:alnum:]]+(?=\")"
        # tar -x -f <tar file> --directory=<directory to place manifest file> manifest.json
        # cat manifest.json | jq .[0].Config | grep -oP "[[:alnum:]]+(?=\.json)"

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
  unset podman_registry_url;#!/bin/bash
fi

