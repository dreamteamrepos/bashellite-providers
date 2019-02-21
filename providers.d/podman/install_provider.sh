#!/usr/bin/env bash

main() {

  local bin_name="podman";
  local dep_check_failed="false";
  local exec_dir="${providers_tld}/${bin_name}/exec"
  local username="bashellite"

  for dep in \
             ${bin_name} \
             jq \
             ; do
    which ${dep} &>/dev/null \
    || {
         echo "[FAIL] Can not proceed until ${dep} is installed and accessible in path.";
         local dep_check_failed="true";
       };
  done;
  if [[ "${dep_check_failed}" == "true" ]]; then
    echo "[FAIL] ${bin_name} provider can not be installed until missing dependencies are installed; exiting." \
    && exit 1;
  fi;

  # Attempt to install Fedora 29 based shadow-utils and libtool compiled for RHEL 7
  # required for podman to be used by non-root user.
  local shadow_utils_package_name="shadow-utils-4.6-4.el7.x86_64"
  local libtool_package_name="libtool-2.4.6-27.el7.x86_64"

  # First check if they are already installed.
  local dep_install_status="true"
  for package in \
                ${shadow_utils_package_name} \
                ${libtool_package_name} \
                ; do
    rpm -qa | grep -oP ${package} &>/dev/null \
    || {
      # Package not found, attempting to install
      yum install -y ${exec_dir}/${package}.rpm
      if [[ $? ]]; then
        echo "[FAIL] ${bin_name} provider dependent package: ${package} failed to install"
        local dep_install_status="false"
      fi
    }
  done

  if [[ "${dep_install_status}" == "false" ]]; then
    echo "[FAIL] Podman non-root user packages installation failed"
    exit 1
  else
    echo "[INFO] Podman non-root user packages installed successfully"
  fi

  # Need to set user.max_user_namespaces to a decent value greater than 0.
  local max_namespaces=$(sysctl user.max_user_namespaces | grep -oP "(?<=user\.max_user_namespaces[[:blank:]]=[[:blank:]])\d+")

  if [[ ${max_namespaces} == "0" ]]; then
    sysctl -q user.max_user_namespaces=15000
  fi

  # Need to add parsing the /etc/subuid and /etc/subgid files looking for the bashellite user to update
  # If bashellite user is not in the files, need to add with a start range higher than what is already present
  # Format of lines in each file:
  # <username>:<subid start value>:<subid range value>

  local subuid_file="/etc/subuid"
  local subgid_file="/etc/subgid"

  for file in ${subuid_file} ${subgid_file}; do
    echo "[INFO] Processing file: ${file}"
    local max_userspace_num=0
    local user_found="false"
    while read line; do
      # Need to break up each line using ':' as a delimiter
      IFS=$':\n'
      local line_array=( ${line} )
      unset IFS
      # Check to see if each line has three values in the line_array, if so, continue processing the line
      if [[ ${#line_array[@]} == 3 ]]; then
        # Check if current user is already found, if so, no need to continue processing file, break from while loop
        if [[ ${line_array[0]} == ${username} ]]; then
          # Set user_found == "true"
          user_found="true"
          break
        fi
        # Process line recording max_userspace_num = subid start value + subid range value
        if [[ ${line_array[1]} > ${max_userspace_num} ]]; then
          max_userspace_num=$((${line_array[1]} + ${line_array[2]}))
        fi
      fi
    done < ${file}
    # Here we check if user is not found, if not, we add the user to the end of the file 
    # with a subid start value == max_userspace_num and a subid range value == 65535 
    if [[ ${user_found} == "false" ]]; then
      if [[ ${max_userspace_num} > 0 ]]; then
        echo "${username}:${max_userspace_num}:65536" >> ${file}
      else
        echo "${username}:100000:65536" >> ${file}
      fi
    fi
  done

  echo "[INFO] ${bin_name} provider successfully installed.";
}

main
