#!/bin/bash

### Program Version:
    script_version="0.1.0-beta"

# Sets timestamp used in log file lines and log file names and other functions
Get_time() {
  timestamp="$(date --iso-8601='ns' 2>/dev/null)";
  timestamp="${timestamp//[^0-9]}";
  timestamp="${timestamp:8:8}";
  if [[ -z "${timestamp}" ]]; then
    echo "[FAIL] Failed to set timestamp; ensure date supports \"--iso-8601\" flag!";
    exit 1;
  fi
}

# This function does a dependency check before proceeding
Check_deps() {
  which which &>/dev/null \
    || { echo "[FAIL] Dependency (which) missing!"; exit 1; };
  for dep in grep \
             date \
             tput \
             basename \
             realpath \
             dirname \
             ls \
             mkdir \
             chown \
             touch \
             cat \
             sed \
             ln \
             tee \
             wget;
  do
    which ${dep} &>/dev/null \
      || { echo "[FAIL] Dependency (${dep}) missing!"; exit 1; };
  done
}

# Ensures that the versions of certain deps are the GNU version before proceeding
Ensure_gnu_deps() {
  for dep in grep \
             date \
             basename \
             realpath \
             dirname \
             ls \
             mkdir \
             chown \
             touch \
             cat \
             sed \
             ln \
             tee;
  do
    grep "GNU" <<<"$(${dep} --version 2>&1)" &>/dev/null \
      || { echo "[FAIL] Dependency (${dep}) not GNU version!"; exit 1; };
  done
}

# These functions are used to generate colored output
#  Info is green, Warn is yellow, Fail is red.
Set_colors() {
  mkclr="$(tput sgr0)";
  mkwht="$(tput setaf 7)";
  mkgrn="$(tput setaf 2)";
  mkylw="$(tput setaf 3)";
  mkred="$(tput setaf 1)";
}

Info() {
  Get_time;
  if [[ ${dryrun} ]]; then
    echo -e "${mkwht}${timestamp} ${mkgrn}[DRYRUN|INFO] $*${mkclr}";
  else
    echo -e "${mkwht}${timestamp} ${mkgrn}[INFO] $*${mkclr}";
  fi
}

Warn() {
  Get_time;
  if [[ ${dryrun} ]]; then
    echo -e "${mkwht}${timestamp} ${mkylw}[DRYRUN|WARN] $*${mkclr}" >&2;
  else
    echo -e "${mkwht}${timestamp} ${mkylw}[WARN] $*${mkclr}" >&2;
  fi
}

Fail() {
  Get_time;
  if [[ ${dryrun} ]]; then
    echo -e "${mkwht}${timestamp} ${mkred}[DRYRUN|FAIL] $*${mkclr}" >&2;
  else
    echo -e "${mkwht}${timestamp} ${mkred}[FAIL] $*${mkclr}" >&2;
  fi
  exit 1;
}

# This function prints usage messaging to STDOUT when invoked.
Usage() {
  echo
  echo "Usage: $(basename ${0}) v${script_version}"
  echo "       [-m mirror_top-level_directory]"
  echo "       [-h]"
  echo "       [-p package_name]"
  #echo "       [-c]"
  echo
  echo "       Required Parameter(s):"
  echo "       -m:  Sets a temporary disk mirror top-level directory."
  echo "            Only absolute (full) paths are accepted!"
  echo "       -p:  The package name to sync."
  #echo "       -c:  The config file to use."
  echo "       Optional Parameter(s):"
  echo "       -h:  Prints this usage message."
}

# This function parses the parameters passed over the command-line by the user.
Parse_parameters() {

  # This section unsets some variables, just in case.
  unset mirror_tld;
  unset package_name;
  unset dryrun;

  mirror_tld=$(pwd)

  # Bash-builtin getopts is used to perform parsing, so no long options are used.
  while getopts ":m:p:h" passed_parameter; do
   case "${passed_parameter}" in
      m)
        mirror_tld="${OPTARG}";
        ;;
      p)
        # Sanitizes the directory name of spaces or any other undesired characters.
	      package_name="${OPTARG//[^a-zA-Z1-9_-]}";
	      ;;
      h)
        Usage;
        exit 0;
        ;;
      *)
        Usage;
        Fail "\nInvalid option passed to \"$(basename ${0})\"; exiting. See Usage below.\n";
        ;;
    esac
  done
  shift $((OPTIND-1));
}

#################################
#
### This section is for functions related to the main execution of the program.
### Functions in this section perform the following tasks:
###   - Check to ensure EUID is 0 before attempting sync
###   - Ensure all required parameters are set before attempting sync
###   - Ensuring appropriate directories exist for mirror
###   - Ensuring appropriate dirs/files exist per repo
###   - Ensuring repo metadata is populated before attempting sync
###   - Ensuring required sync providers are installed and accesssible
###   - Performing the sync
###   - Reporting on the success of the sync
#
################################################################################

Validate_variables() {

  # This santizes the directory name of spaces or any other undesired characters.
  mirror_tld="${mirror_tld//[^a-zA-Z1-9_-/]}";
  mirror_tld=${mirror_tld//\"};
  if [[ "${mirror_tld:0:1}" != "/" ]]; then
    Usage;
    Fail "\nAbsolute paths only, please; exiting.\n";
  else
    # Drops the last "/" from the value of mirror_tld to ensure uniformity for functions using it.
    # Note: as a side-effect, this effective prevents using just "/" as the value for mirror_tld.
    mirror_tld="${mirror_tld%\/}";
  fi

  # Ensures repo_name_array is not empty
  #if [[ -z "${repo_name_array}" ]]; then
  #  Fail "Bashellite requires at least one valid repository.";
  #fi

  # If the mirror_tld is unset or null; then exit.
  # Since the last "/" was dropped in Parse_parameter,
  # If user passed "/" for mirror_tld value, it effectively becomes "" (null).
  if [[ -z "${mirror_tld}" ]]; then
    Usage;
    Fail "\nPlease set the desired location of the local mirror; exiting.\n";
  fi
}

# This function creates/validates the file/directory framework for the requested package.
Validate_package_framework() {
  if [[ -n "${package_name}" ]]; then
    Info "Creating/validating directory and file structure for mirror and package (${package_name})...";
    #mkdir -p "${providers_tld}";
    mirror_package_name="${package_name//__/\/}";
    if [[ ! -d "${mirror_tld}" ]]; then
      Fail "Mirror top-level directory (${mirror_tld}) does not exist!"
    else
      mkdir -p "${mirror_tld}/${mirror_package_name}/" &>/dev/null \
      || Fail "Unable to create directory (${mirror_tld}/${mirror_package_name}); check permissions."
    fi
  fi
}

# This function performs the actual sync of the package
Sync_package() {
  # Need to add using wget to query the pypi.org site's /simple/package/ directory to get 
  # the index file that has the list of versions of the package.
  # local recurse_flag="-r -l inf -np";
  # local wget_args="${wget_args} -nv -nH -e robots=off -N"
  # local wget_args="${wget_args} ${recurse_flag}"
  # local wget_args="${wget_args} --accept "${wget_filename}""
  # local wget_args="${wget_args} --reject "index*""
  # local wget_args="${wget_args} -P "${_r_mirror_tld}/${_n_mirror_repo_name}/""
  # local wget_args="${wget_args} "${_n_repo_url}/${wget_include_directory}${wget_filename}" "
  # wget ${wget_args} 2>&1 \
  # | grep -oP "(?<=(URL: ))http.*(?=(\s*200 OK$))" \
  # | while read url; do utilMsg INFO "$(utilTime)" "Downloaded $url"; done
  # if [[ "${PIPESTATUS[1]}" == "0" ]]; then
  local pypi_url="https://pypi.org"
  local base_dir="${mirror_tld}/${mirror_package_name}/web"
  mkdir -p "${base_dir}" &>/dev/null \
      || Fail "Unable to create directory (${base_dir}); check permissions."

  # Step 1. Get package listing from $pypi_url/simple/$mirror_package_name/ 
  # Step 2. For each package listing, modify it to point to ../../packages/<packages directory>
  # and save it to $base_dir/simple/$mirror_package_name/index.html
  # Step 3. Save non package listing lines to previous index.html
  # Step 4. For each package listing, download package and save
  # it to $base_dir/packages/<packages directory>
  local simple_dir="${base_dir}/simple"

  mkdir -p "${simple_dir}" &>/dev/null \
      || Fail "Unable to create directory (${simple_dir}); check permissions."

  local packages_dir="${base_dir}/packages"

  mkdir -p "${packages_dir}" &>/dev/null \
      || Fail "Unable to create directory (${packages_dir}); check permissions."

  local package_name_dir="${simple_dir}/${mirror_package_name}"

  mkdir -p "${package_name_dir}" &>/dev/null \
      || Fail "Unable to create directory (${package_name_dir}); check permissions."

  cat /dev/null > ${package_name_dir}/index.html

  curl -s ${pypi_url}/simple/${mirror_package_name}/ \
  | while read line; do
    echo "${line}" >> ${package_name_dir}/index.html
  done
  
}

################################################################################


################################################################################
### PROGRAM EXECUTION ###
#########################
### This section is for the execution of the previously defined functions.
################################################################################

# These complete prepatory admin tasks before executing the sync functions.
# These functions require minimal file permissions and avoid writes to disk.
# This makes errors unlikely, which is why verbose logging is not enabled for them.
Check_deps \
&& Ensure_gnu_deps \
&& Set_colors \
&& Parse_parameters ${@} \

# This for-loop executes the sync functions on the appropriate package.
# Logging is enabled for all of these functions; some don't technically need to be in the loop, except for logging.
if [[ "${?}" == "0" ]]; then
  Info "Starting ${0} for package (${package_name})..."
  for task in \
              Validate_variables \
              Validate_package_framework \
              Sync_package;
  do
    ${task};
  done
else
  # This is ONLY executed if one of the prepatory/administrative functions fails.
  # Most of them handle their own errors, and exit on failure, but a few do not.
  echo "[FAIL] ${0} failed to execute requested tasks; exiting!";
  exit 1;
fi
################################################################################
