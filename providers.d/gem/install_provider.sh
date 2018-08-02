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

  local gemlist

  for gem in \
      bundler \
      rake \
      hoe \
      ; do
    gemlist=$(gem list)
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

  gemlist=$(gem list)
  local gem="net-http-persistent"
  if [[ "${gemlist}" != *"${gem}"* ]]; then 
    echo "[WARN] ${gem} gem dependency not found.  Installing..."
    gem install -i /usr/share/gems ${gem} -v 2.9.4
    gemlist=$(gem list)
    if [[ "${gemlist}" == *"${gem}"* ]]; then
      echo "[INFO] ${gem} installed successfully..."
    else
      echo "[FAIL] ${gem} was NOT installed successfully; exiting." \
      && exit 1;
    fi
  fi

  gemlist=$(ls ${providers_tld}/gem/exec/gems)
  gem="rubygems-mirror"
  if [[ "${gemlist}" != *"${gem}"* ]]; then 
    echo "[WARN] ${gem} gem dependency not found.  Installing..."
    gem install -i ${providers_tld}/gem/exec ${gem}
    gemlist=$(ls ${providers_tld}/gem/exec/gems)
    if [[ "${gemlist}" == *"${gem}"* ]]; then
      echo "[INFO] ${gem} installed successfully..."
    else
      echo "[FAIL] ${gem} was NOT installed successfully; exiting." \
      && exit 1;
    fi
  fi

  echo "[INFO] ${bin_name} provider successfully installed.";
}

main