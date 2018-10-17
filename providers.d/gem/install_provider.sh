#!/usr/bin/env bash

main() {

  local bin_name="ruby";
  local ruby_ver="2.5.1";

  for dep in \
             git \
             make \
             ; do
    which ${dep} &>/dev/null \
    || {
         echo "[FAIL] Can not proceed until ${dep} is installed and accessible in path." \
         && exit 1;
       };
  done;

  # Check to see if ruby is already installed in /home/bashellite/.rubies, if not install it.
  local ruby_bin="/home/bashellite/.rubies/ruby-${ruby_ver}/bin/ruby"
  if [[ -s "${ruby_bin}" && $(${ruby_bin} --version | grep -o "ruby ${ruby_ver}") == "ruby ${ruby_ver}" ]]; then
    echo "[INFO] ${bin_name} provider successfully installed.";
  else
    echo "[WARN] ${bin_name} does NOT appear to be installed, (or it is broken); (re)installing..."
    # Download ruby-install
    if [ ! -d ${providers_tld/gem/src/ruby-install} ]; then
      git clone https://github.com/pcseanmckay/ruby-install ${providers_tld}/gem/src/ruby-install
    fi
    
    # Install ruby to /home/bashellite/.rubies
    local ruby_installer="${providers_tld}/gem/src/ruby-install/bin/ruby-install"
    local ruby_src_dir="${providers_tld}/gem/src/ruby_src"
    local ruby_install_dir="/home/bashellite/.rubies/ruby-${ruby_ver}"
    
    ${ruby_installer} -i ${ruby_install_dir} -s ${ruby_src_dir} ruby ${ruby_ver}
    chown -R bashellite:bashellite /home/bashellite/.rubies
    chmod -R 0700 /home/bashellite/.rubies

    # Check installation of ruby
    if [[ -s "${ruby_bin}" && $(${ruby_bin} --version | grep -o "ruby ${ruby_ver}") == "ruby ${ruby_ver}" ]]; then
      echo "[INFO] ${bin_name} provider successfully installed.";
    else
      echo "[FAIL] ${bin_name} was NOT installed successfully; exiting." \
      && exit 1;
    fi
  fi

}

main