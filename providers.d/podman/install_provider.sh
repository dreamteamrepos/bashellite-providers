#!/usr/bin/env bash

main() {

  local bin_name="podman";
  local dep_check_failed="false";
  local exec_dir="${providers_tld}/${bin_name}/exec"

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

  echo "[INFO] ${bin_name} provider successfully installed.";
}

main
