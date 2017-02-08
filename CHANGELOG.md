# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

This changelog adheres to [Keep a CHANGELOG](http://keepachangelog.com/).

## [Unreleased]

## [0.10.0] - released on 2017-02-08
### Added
- Initial support to the Makefile to enable metrics collection during a build

### Changed
- Overhaul of how vanagon handles environment variables. Vanagon now has an
  environment class that allows users to scope environment variables to be
  project specific, platform specific, or component specific

## [0.9.2] - released on 2017-01-31
### Added
- Experimental `render` command added to aid in rapid Makefile iteration and testing 

### Deprecated
- is_osx? method deprecated in favor of is_macos? ([VANAGON-28](https://tickets/puppetlabs.com/browse/VANAGON-28))

### Changed
- Updated to Rubocop 0.47.x
- MAINTAINERS file updated with current project maintainers

## [0.9.1] - released on 2017-01-09
This is a bug-fix release to replace the yanked 0.9.0 release.

### Fixed
- The DSL code underneath the Component source checksums was refactored in
  0.9.0. Tests passed, but the code was broken. Upon triage we discovered
  that those code paths were never well tested to begin with, which is how
  the bug was missed. The DSL code paths in question have been improved,
  and the bug has been corrected.
- We sanitize the `ENV` hash further while testing token support in the
  vmpooler engine.

## [0.9.0] - released on 2017-01-06; yanked on 2017-01-06
### Added
- Support for reading vmpooler tokens from a 
  [vmfloaty](https://github.com/briancain/vmfloaty) config file.
  The new order of precedence for defining vmpooler tokens is:
    - `VMPOOLER_TOKEN` environment variable
    - Reading it from the file `~/.vmpooler-token`
    - Reading it from the file `~/.vmfloaty.yml`
- A Rakefile to help ease common development tasks, like running spec tests, code coverage,
  and Rubocop. `bundle exec rake -T` away!
- Added `--only-build` flag, allowing developers to build a subset of components 
  from a Vanagon project.

### Changed
- RPMs built with Vanagon now depend on `/bin/mkdir` and `/bin/touch`. 
  RPM `pre-` and `post-` scripts use those commands, but the packages did not
  express that dependency. This resolves a problem reported by Mike Schmidt
  in [CPR-393](https://tickets.puppetlabs.com/browse/CPR-393).
- Git sources now support repositories in a detached HEAD state, so pre-staged
  and shallow-cloned repositories on disk are valid sources for individual components.
- Local sources now support recursive local directories (expressed as `file://` URIs)
  as valid sources for individual component.

### Fixed
- Any spec tests that used `/tmp` as a hardcoded temporary directory location
  now use `Dir.mktmpdir` instead. Safety first!

## [0.8.2] - 2016-09-29
### Changed
- Fixed bug to make md5 the default checksum type for component add_source()

## [0.8.1] - 2016-09-28
### Changed
- Enable brp strip scripts for stripping binaries on Cisco RPM platforms
- MAINTAINERS file updated with current project maintainers
- Vanagon now supports sha256sum and sha512sum checksum validation in its DSL

## [0.8.0] - 2016-08-11
### Changed
- Git component source handling has been offloaded to an external library (`ruby-git`).
- Git functionality now supports virtually all variants of acceptable Git URIs (including the all-too-common Triplet format of `<user>@<host>:<repo>.git`).
- HTTP component sources now follow URL redirects.
- Component sources support many more archive types, with support for bzip2, xz, rar, etc.
- Vanagon now uses a clear heuristic to determine what sort of operation to perform for Component sources:
  1. Git
  2. HTTP/HTTPS
  3. Local filesystem
  4. Give up
- More status messages and error messages. Vanagon still exits with a stack dump if operations don't succeed but at least now the output is slightly more meaningful.
- Reverted the change to default output directories for el and deb to pre 0.7.0
  defaults.

## [0.7.1] - 2016-08-01
### Changed
- MSI names will output as NAME-VERSION-ARCH.MSI

## [0.7.0] - 2016-07-27
### Changed
- Vanagon now uses one defaut output path for all platforms, with an option
  to override the default using platform.output_dir in the platform config
- MSIs no longer contian _VANAGON in the name
- Update rubocop to 0.41.2

### Fixed
- Fix building packages without stripping static archives

## [0.6.3] - 2016-06-29
### Changed
- On AIX, services are stopped on upgrade.

## [0.6.2] - 2016-06-27
### Added
- Inspectable components
- Documentation (incomplete)
- ec2 engine
- There is now a VANAGON_RETRY_COUNT environment variable to set retry counts
- There is now a VANAGON_TIMEOUT environment variable to set timeout

### Changed
- Increased the default timeout on retry logic
- Put retry logic around fetching sources
- Vanagon no longer retries makefile execution
- Windows WiX "defaults" have been removed, and examples have been
  added to the examples directory
- Default retry count is now 1

### Fixed
- Retry logic prints out error messages
- AIX and el 4 upgrades / installs no longer leave files under rpmstatedir

## [0.6.1] - 2016-04-27
### Added
- Added is_cross_compiled? utility methods to specify if a platform is cross-compiled

### Fixed
- Vanagon now follows HTTP redirects
- make timeout accessible in the dsl

## [0.6.0] - 2016-04-15
### Added
- With this release the vanagon MSI engine has stabilized and is now ready for
  use!

### Fixed
- Updates in the deb/rpm conflicts functionality did not work correctly with
  deb-based systems. Both 'Replaces' and 'Breaks' are specified in the
  control script when replaces are added to vanagon now.
- Make retry_count accessible in the dsl.
- Update to not pass the platform flag to the WiX compiler options since the
  erb engine will populate fields based on platform.

### Changed
- Vanagon::Component::Source::LocalSource was renamed to
  Vanagon::Component::Source::Local for consistency with naming elsewhere in
  the project.

## [0.5.10] - 2016-04-08
### Fixed
- Fixes to version string handling: now reject empty strings
  so we don't get bad versions (thanks to Colin Wood for the
  contribution)
- Solaris services will now correctly reference the SMF service type,
  which should enable proper service restarts on package upgrades.

### Changed
- Local file sources added with the add_source function no longer
  require checksums.

## [0.5.9] - 2016-3-31
### Fixed
- Fixes to deb/rpm conflicts functionality

## [0.5.8] - 2016-3-29
### Fixed
- Fixes to OS X postinstall for services

### Added
- Added the ability to specify conflicts in our deb and rpm packages

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

[Unreleased]: https://github.com/puppetlabs/vanagon/compare/0.10.0...HEAD
[0.10.0]: https://github.com/puppetlabs/vanagon/compare/0.9.2...0.10.0
[0.9.2]: https://github.com/puppetlabs/vanagon/compare/0.9.1...0.9.2
[0.9.1]: https://github.com/puppetlabs/vanagon/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/puppetlabs/vanagon/compare/0.8.2...0.9.0
[0.8.2]: https://github.com/puppetlabs/vanagon/compare/0.8.1...0.8.2
[0.8.1]: https://github.com/puppetlabs/vanagon/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/puppetlabs/vanagon/compare/0.7.1...0.8.0
[0.7.1]: https://github.com/puppetlabs/vanagon/compare/0.7.0...0.7.1
[0.7.0]: https://github.com/puppetlabs/vanagon/compare/0.6.3...0.7.0
[0.6.3]: https://github.com/puppetlabs/vanagon/compare/0.6.2...0.6.3
[0.6.2]: https://github.com/puppetlabs/vanagon/compare/0.6.1...0.6.2
[0.6.1]: https://github.com/puppetlabs/vanagon/compare/0.6.0...0.6.1
[0.6.0]: https://github.com/puppetlabs/vanagon/compare/0.5.10...0.6.0
[0.5.10]: https://github.com/puppetlabs/vanagon/compare/0.5.9...0.5.10
[0.5.9]: https://github.com/puppetlabs/vanagon/compare/0.5.8...0.5.9
[0.5.8]: https://github.com/puppetlabs/vanagon/compare/0.5.7...0.5.8
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
