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
  ${providers_tld}/google-repo/exec/repo --help &>/dev/null \
  || {
       echo "[WARN] google's repo does NOT appear to be installed, (or it is broken); (re)installing..." \
       && rm -fr ${providers_tld}/google-repo/exec/* &>/dev/null;
     };
  # Ensure bandersnatch installed successfully
  {
    ${providers_tld}/bandersnatch/exec/bin/bandersnatch --help &>/dev/null \
    && echo "[INFO] bandersnatch installed successfully...";
  } \
  || {
       echo "[FAIL] bandersnatch was NOT installed successfully; exiting." \
       && exit 1;
     };
}

main
