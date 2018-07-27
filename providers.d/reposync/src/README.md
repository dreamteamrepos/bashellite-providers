#Source code files

This directory contains any source code files used by the provider's `install_provider.sh` script to install a provider that can/should not be installed globally via the operating system's package manager. The resulting executable files generated from this source code  usually includes binaries that reside in a python/ruby virtualenv, inside of `../exec`, or a globally installed provider that resides in `/usr/local/bin`.

Once installed, these binaries and/or executable scripts are then called by the `bashellite` command-line utility when appropriate, and the source code is no longer needed unless a reinstall/update is performed.

Note: not all providers are installed this way, so this directory may be empty.
