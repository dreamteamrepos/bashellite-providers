#Source code files

This directory contains any source code files used by the provider's `install_provider.sh` script to install a provider that can/should not be installed globally via the operating system's package manager. The resulting executable files generated from this source code  usually includes binaries that reside in a python/ruby virtualenv, inside of `../exec`, or a globally installed provider that resides in `/usr/local/bin`.

Once installed, these binaries and/or executable scripts are then called by the `bashellite` command-line utility when appropriate, and the source code is no longer needed unless a reinstall/update is performed.

Note: not all providers are installed this way, so this directory may be empty.

This directory contains 2 src rpms that from Fedora 29 that are required to be rebuilt on a RHEL 7 system.  Shadow-utils requires libtool v 2.4.6.  Libtool must be compiled with the version of gcc used by RHEL 7 to work properly for installing the Fedora 29 version of shadow-utils under RHEL 7.  Fedora 29 shadow-utils is required by podman under RHEL 7 to allow non-root users (bashellite user) to use podman.

Note: Before compiling libtool under RHEL 7, the libtool src rpm spec file must be modified to change the line: Requires: gcc(major) = %{gcc_major} to Requires: gcc for the compiled libtool binary rpm to install correctly.
