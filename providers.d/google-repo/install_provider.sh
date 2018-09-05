#!/usr/bin/env bash

main() {

  #local providers_tld="/opt/bashellite/providers.d";

  for dep in \
             git \
             curl \
             rm \
             ; do
    which ${dep} &>/dev/null \
    || {
         echo "[FAIL] Can not proceed until ${dep} is installed and accessible in path; exiting." \
         && exit 1;
       };
  done
  # If git is installed, ensure google's repo is installed in proper location, and functional.
  # If google's repo is not installed, or broken, blow away the old one, and install a new one.
  if [ ! -s "${providers_tld}/google-repo/exec/repo" ]
  then
    echo "[WARN] google's repo does NOT appear to be installed, (or it is broken); (re)installing..." \
    && rm -fr ${providers_tld}/google-repo/exec/* &>/dev/null \
    && curl https://storage.googleapis.com/git-repo-downloads/repo > ${providers_tld}/google-repo/exec/repo \
    && chmod ug+x ${providers_tld}/google-repo/exec/repo;
    
    # Ensure bandersnatch installed successfully
    if [ -s "${providers_tld}/google-repo/exec/repo" ]
    then
      echo "[INFO] google-repo installed successfully..."
    else
      echo "[FAIL] google-repo was NOT installed successfully; exiting." \
      && exit 1;
    fi
  else
    echo "[INFO] google-repo successfully installed."
  fi

}

main
