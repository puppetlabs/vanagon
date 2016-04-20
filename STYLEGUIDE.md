To make our project and component config files consistent and readable, file contents should be laid out using the following five sections, with each section commented using the following section headers:

# Source-Related Metadata

This section consists of any metadata related to the upstream sources or patch additions we require, including:

* Version
* Source URI
* Patches
* md5sums for the sources

# Package Dependency Metadata

This section contains metadata about the interaction between packages, including:

* Runtime requirements
* pkg.replaces
* pkg.conflicts

# Build requirements

This section is only focused on listing build-time requirements for the software:

* build_requires

# Build-time configuration

This section contains customizations for how the package gets configured and compiled, including:

* Configure options
* PATH/CFLAGS/LDFLAGS and other environment variable settings

# Build Commands

This section consists of the shell commands needed to configure, build, and install the software. If customizations are needed on a per-platform basis, they should come from the use of variables that were defined in previous sections. 

* pkg.configure
* pkg.build
* pkg.install
