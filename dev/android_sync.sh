#!/bin/bash

mirror_loc=$1
repo_url="https://android.googlesource.com/mirror/manifest"

mkdir -p ${HOME}/bin

curl https://storage.googleapis.com/git-repo-downloads/repo > ${HOME}/bin/repo
chmod a+x ${HOME}/bin/repo

mkdir -p ${mirror_loc}
cd ${mirror_loc}
if [ ! -d ".repo" ]; then
  ${HOME}/bin/repo init -u ${repo_url} --mirror
fi
${HOME}/bin/repo sync