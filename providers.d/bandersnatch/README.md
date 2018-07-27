#Provider Directory

This directory contains, source code (if applicable), executables (if applicable), example configs, test configs (w/mock data), an installer script, and the wrapper function for a bashellite provider.

For specific instructions on how to configure this provider, please see `configs/PROVIDER.CONF.md`.

For example configurations, please see the files located in `configs/examples/`.

For configs used during integration testing of this provider, please see `configs/test/`.

For the executable files that make up the provider (when not globally installed), please see `exec/` (Note: these are generated at install time, so if you are reading this in version control, you should not see anything in this directory).

For the source code associated with this provider (if not globally installed via the package manager), please see `src/`.

For the installer script for this provider, please see `install_provider.sh`.

For the wrapper function(s) that actually calls the provider's executable, please see `provider_wrapper.sh`.

For general information about providers, please see the main `README.md` for this entire repository.
