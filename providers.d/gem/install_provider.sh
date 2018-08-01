#!/usr/bin/env bash

main() {

  local bin_name="gem";

  for dep in \
             ruby \
             ${bin_name} \
             ; do
    which ${dep} &>/dev/null \
    || {
         echo "[FAIL] Can not proceed until ${dep} is installed and accessible in path." \
         && exit 1;
       };
  done;

  for gem in \
      bundler \
      rake \
      hoe \
      rubygems-mirror \
      net-http-persistent \
      ; do
    local gemlist=$(gem list)
    if [[ "${gemlist}" != *"${gem}"* ]]; then 
      echo "[WARN] ${gem} gem dependency not found.  Installing..."
      gem install ${gem}
      gemlist=$(gem list)
      if [[ "${gemlist}" == *"${gem}"* ]]; then
        echo "[INFO] ${gem} installed successfully..."
      else
        echo "[FAIL] ${gem} was NOT installed successfully; exiting." \
        && exit 1;
      fi
    fi 
  done

  echo "[INFO] ${bin_name} provider successfully installed.";
}

main