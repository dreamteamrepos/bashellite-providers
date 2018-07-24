#!/usr/bin/env bash

main() {

  local bin_name="apt-mirror";
  local dep_check_failed="false";

  for dep in \
             git \
             wget \
             pod2man \
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
  which ${bin_name} &>/dev/null \
    || { \
          echo "[WARN] apt-mirror not installed... installing." \
          && rm -fr ${providers_tld}/apt-mirror/src/ \
          && git clone https://github.com/apt-mirror/apt-mirror.git ${providers_tld}/apt-mirror/src/ \
          && cd ${providers_tld}/apt-mirror/src/ \
          && make install;
       };
  if [[ "$(${bin_dir}/${bin_name} --bad-flag &>/dev/null; echo ${?};)" == "2" ]]; then
    echo "[INFO] ${bin_name} provider successfully installed.";
  else
    echo "[FAIL] ${bin_name} provider NOT successfully installed; exiting.";
    exit 1;
  fi
}

main
