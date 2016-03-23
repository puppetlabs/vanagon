# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

This changelog adheres to [Keep a CHANGELOG](http://keepachangelog.com/).

## [Unreleased]

## [0.5.7] - 2016-3-23
### Added
- MSI for vanagon PRE-RELEASE. MSI functionality for vanagon is starting
  in to the testing phase, this release includes that functionality

## [0.5.6] - 2016-3-21
### Fixed
- Re-added the previous Debian architecture change, fixed for all
Debian and Ubuntu platforms.
- Fixed syntax issues in the osx pre and post install scripts

## [0.5.5] - 2016-3-21
### Fixed
- Reverted the change to specify debian architectures, the option was breaking
on Debian < 8 and needs more work and testing.

## [0.5.4] - 2016-3-21
### Fixed
- Fixed a condition where services were not being reloaded on upgrade for OSX

### Added
- It is now possible to specify architecture when generating deb packages

## [0.5.3] - 2016-3-15
### Added
- Solaris builds will now attempt to restart services after a package upgrade
- Vanagon builds will retry some error-prone build steps (and log the output)

## [0.5.2] - 2016-3-08
### Fixed
- Vanagon no longer fails if the destination path already exists
- "gem install" no longer fails when bundler is in use due to a polluted
  environment

### Added
- If rspec is called with '--require spec_helper' as an option, a helper
  will swallow output of $stdout and $stderr

## [0.5.1] - 2016-2-04
### Changed
- Vanagon now assumes anything that is not listed as an archive is just
  a file, and thus NON-ARCHIVE-EXTENSIONS no longer needs to be updated
  for new extentions.

### Fixed
- Builds will halt if any git command fails
- Hardware engine will release locks on failures
- Builds no longer fail if things items were in /usr/local on debian
- on RPM builds, if there are no directories to package builds no longer
  fail
- Repeated builds no longer fail due to a symlink issue

### Added
- Added functionality to enable SSH forwarding in to vanagon pooler hosts
- Added functionality to build nuget archives
- Added support for patching gems

## [0.5.0] - 2016-1-06
### Changed
- Replaced the ERB template based Makefile generation with a procedural
  Makefile backend

### Fixed
- Added build_dir function for when tools need to be moved away from the
  regular build directory to avoid conflicts with build files and source
  files
- Vanagon-generated packages no longer change group
  ownership of files when installed on Solaris 10

### Added
- Added lock_manager gem to vanagon project
- Added hardware engine
- Added support for .vim, .json and .service config files
- Added support for zip files

## [0.4.1] - 2015-11-12
### Changed
- Fixed an issue where, with test builds when the version string contains
  a git sha alphanumeric component, the Solaris 11 VERSION file contains
  the transformed IPS-compatible version string (with the alpha characters
  stripped). Now the VERSION file will be consistent across all of the
  platforms.

## [0.4.0] - 2015-11-03
### Added
- xml files are now valid http component sources
- bill_of_materials method added to project DSL to allow BOM to be placed in a
  specific location instead of the system docdir
- post and pre package install actions available for deb and rpm packages in
  the component DSL

### Changed
- Platform DSL methods apt_repo, zypper_repo and yum_repo deprecated in favor
  of the generic add_build_repository that is platform agnostic
- The add_pre_install_action component DSL method has a new signature that has
  two required arguments (script and package state).

### Fixed
- Empty directories will now be included when they previously may not have been
- /var/run moved to /system/volatile on solaris 11
- Links outside of the project directories will now be included in packages

### Removed
- Nxos support has been removed and replaced by cisco-wrlinux

## [0.3.19] - 2015-10-16
### Fixed
- Solaris 11 manifests now correctly handle services installed into
  subdirectories such as network
- User creation now correctly includes --system if needed

## [0.3.18] - 2015-10-14
### Changed
- Move Vanagon bill-of-materials location on OSX from /usr to /usr/local
- Rename vcloud_name to vmpooler_template in platform DSL

### Fixed
- Ensure AIX doesn't include newlines when adding AIX services
- Only install curl if missing when adding yum repositories in platform provisioning
- Update Makefile targets to finish build dependencies before configuring dependents

## [0.3.17] - 2015-10-02
### Added
- Initial support for custom pre- and post-install actions from the component
  level. Currently implemented for RPM, we will expand that as needed.
- platform_triple now available as a platform DSL method. Very useful when
  cross-compiling.
- replaces and provides are now available in the project DSL (they were
  previously only available in the component DSL)

### Changed
- apply_patch component DSL method now accepts fuzz and strip as arguments for
  patches that don't apply cleanly with just -p1. patch application now ignores
  whitespace by default

## [0.3.16] - 2015-09-24
### Fixed
- Configfiles installed explicitly on debian

## [0.3.15] - 2015-09-22
### Added
- Support for AIX services
- .sh and .csh added as valid plaintext file sources
- WindRiver Linux added as a distinct platform type subclassing RPM

### Changed
- File/configfile implementation refactored to remove duplicate file issues in
  rpm packaging.

### Fixed
- AIX rpm spec no longer requires chkconfig

### Removed
- aix_package dsl method was removed. Packages desired for a build should be
  added as build_requires or via platform provisioning.

## [0.3.14] - 2015-09-15
### Changed
- OSX packages no longer include the platform codename and instead use
  the platform version.

## [0.3.13] - 2015-09-14
### Added
- Pooler engine now has token support to ensure long template life. Use
  VMPOOLER_TOKEN environment variable or write token into ~/.vanagon-token

### Changed
- Noarch project method is now applied to solaris packages

### Fixed
- Cross compiles will no longer attempt to install the produced package on
  solaris 11.

## [0.3.12] - 2015-09-03
### Changed
- Empty directories now included in vanagon builds

### Fixed
- Broken usage of ips_version fixed for solaris 11

## [0.3.11] - 2015-09-02
### Added
- Solaris 11 support
- Support a custom release string in package names
- Support platform-specific 'install' commands
- Miscellaneous updates to better support Mac OS X, Solaris, and AIX

### Changed
- Updated Mac OS X package name and directory structure to match other platforms

## [0.3.10] - 2015-08-26
### Added
- Added a CHANGELOG.md to track high level user facing changes
- Include HuaweiOS for RPM5 tweaks

### Changed
- Update vanagon_hosts.log format to use FQDN instead of the short name
- Updates to RPM scriptlets for consistency and better handling of upgrades

## Versions <= 0.3.9 do not have a change log entry

[Unreleased]: https://github.com/puppetlabs/vanagon/compare/0.5.7...HEAD
[0.5.7]: https://github.com/puppetlabs/vanagon/compare/0.5.6...0.5.7
[0.5.6]: https://github.com/puppetlabs/vanagon/compare/0.5.5...0.5.6
[0.5.5]: https://github.com/puppetlabs/vanagon/compare/0.5.4...0.5.5
[0.5.4]: https://github.com/puppetlabs/vanagon/compare/0.5.3...0.5.4
[0.5.3]: https://github.com/puppetlabs/vanagon/compare/0.5.2...0.5.3
[0.5.2]: https://github.com/puppetlabs/vanagon/compare/0.5.1...0.5.2
[0.5.1]: https://github.com/puppetlabs/vanagon/compare/0.5.0...0.5.1
[0.5.0]: https://github.com/puppetlabs/vanagon/compare/0.4.1...0.5.0
[0.4.1]: https://github.com/puppetlabs/vanagon/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/puppetlabs/vanagon/compare/0.3.19...0.4.0
[0.3.19]: https://github.com/puppetlabs/vanagon/compare/0.3.18...0.3.19
[0.3.18]: https://github.com/puppetlabs/vanagon/compare/0.3.17...0.3.18
[0.3.17]: https://github.com/puppetlabs/vanagon/compare/0.3.16...0.3.17
[0.3.16]: https://github.com/puppetlabs/vanagon/compare/0.3.15...0.3.16
[0.3.15]: https://github.com/puppetlabs/vanagon/compare/0.3.14...0.3.15
[0.3.14]: https://github.com/puppetlabs/vanagon/compare/0.3.13...0.3.14
[0.3.13]: https://github.com/puppetlabs/vanagon/compare/0.3.12...0.3.13
[0.3.12]: https://github.com/puppetlabs/vanagon/compare/0.3.11...0.3.12
[0.3.11]: https://github.com/puppetlabs/vanagon/compare/0.3.10...0.3.11
[0.3.10]: https://github.com/puppetlabs/vanagon/compare/0.3.9...0.3.10
