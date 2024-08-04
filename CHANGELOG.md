# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](https://semver.org).

This changelog adheres to [Keep a CHANGELOG](https://keepachangelog.com).

## [Unreleased]
- Bump minimum ruby requirement to 2.7
- Fix preserve param default behaving like `always` but should be `on-failure`

## [0.52.0] - 2024-06-03
### Added
- Add Amazon 2 (ARM) platform definition to vanagon

## [0.51.0] - 2024-05-31
### Added
- (VANAGON-243) Add Ubuntu 24.04 (ARM) platform definition to vanagon

## [0.50.0] - 2024-04-29
### Changed
(PA-6262) Change cmake to cmake3 form amazon linux 2 arm

## [0.49.0] - 2024-04-29
### Fixed
- Use URI.parse when selecting the docker target
### Added
- (VANAGON-242) Add Amazon Linux2 ARM platform definition to vanagon

## [0.48.0] - 2024-04-16
### Added
- (PA-6347) Add Fedora 40 platform definition to vanagon

## [0.47.0] - 2024-04-03
### Added
- (PA-5323) Add RedHat 9 (Power9) platform definition to vanagon

## [0.46.0] - 2024-03-18
### Changed
- (RE-16095) Abandon fustigit in favor of build-uri. build-uri provides similar functionality
  without the monkey-patching

## [0.45.0] - 2024-02-16
### Added
- (VANAGON-228) Add Fedora-38 (Intel) platform definition to vanagon
- (RE-16102) Add Redhat-9 FIPS platform definition to vanagon
- (VANAGON-239) Add Ubuntu 24.04 (x86_64) platform definition

## [0.44.0] - 2023-11-30
### Added
- (VANAGON-237) Add macOS 14 (ARM) platform definition to vanagon
- (VANAGON-236) Add macOS 14 (Intel) platform definition to vanagon
- (maint) Add Debian 12 bookworm platform definitions

## [0.43.0] - 2023-11-20
### Added
- (PA-5947) Add Amazon Linux platform utility matcher, update RPM project spec template to require coreutils that are symlinked.

## [0.42.0] - 2023-11-09
### Added
- (PA-5786) Add revised `postinstall_required_actions` forcing scriptlets to run in the %post section for rpm

### Changed
- (VANAGON-235) Report the actual URL when a Git URL is deemed invalid.

## [0.41.0] - 2023-10-26
### Added
- (VANAGON-231) Added amazon linux 2023 platform for intel & arm

### Removed
- Reverted "(PA-5786) Add ability to execute direct post installation scriptlets"

## [0.40.0] - 2023-10-24
### Added
- (PA-5786) Add `postinstall_required_actions` forcing scriptlets to run in the %post
  section for rpm

## [0.39.3] - 2023-09-29
### Added
- (PA-5328) Add support for Debian 11 (ARM64)

### Changed
- (maint) Force psych gem to use >= 4.0 to avoid breaking change in safe_load between v3 and
  v4 of the gem.

## [0.39.2] - 2023-08-29
### Fixed
- (maint) Handle an invalid mirror gracefully

## [0.39.1] - 2023-08-25
### Fixed
- (maint) Fix git remote detection
- (maint) Fix valid_url? check

## [0.39.0] - 2023-08-07
### Added
- (PA-5701) Allow platform's name to be overridden

## [0.38.0] - 2023-07-05

### Added
- (maint) Adds `brew` attribute to specify the path of Homebrew on macOS on different architectures.
- (PA-5329) Add macOS 13 (ARM64)
- (PA-5326) Added macos 13 (x86_64)

## [0.37.1] - 2023-06-21
### Changed
- (maint) Add TLS 1.2 to the platform add command for Windows
- (maint) Use keyword arguments

## [0.37.0] - 2023-06-13
### Fixed
- (VANAGON-227) Be more discerning when declaring a URI starting with 'https://github.com/'
  as a git repository for source purposes.
- (VANAGON-232) Be a bit more polite when ABS times out allocating a VM.

### Removed
- (PA-5327) Remove OSX 10.15 (x86_64)
- (PA-5331) Red Hat 7 (aarch64)

### Changed
- (maint) Add gpg key to provisioning step for default ubuntu-22.04-amd64 config.

## [0.36.0] - 2023-04-18
### Fixed
- (VANAGON-226) Fix problems with running on Ruby 3.0 - 3.2
- (VANAGON-204) Fix and update some rspec tests for Ruby 3

## [0.35.1] - 2023-03-21
### Changed
- (maint) Name file in deb build 'buildinfo' instead of 'build' to make signing work with newer versions of debsign.

## [0.35.0] - 2023-02-14
### Changed
- (VANAGON-211) Speed up file listings on Windows
- (VANAGON-214) Create home directory on macOS before installing brew, add
  macOS 11 & 12 ARM definitions, and opt-out from homebrew analytics.

## [0.34.0] - 2023-01-16
### Changed
- (PA-4841) Update platform default for Ubuntu 18.04 aarch64/ARM64

## [0.33.0] - 2023-01-13
### Changed
- (PA-4838) Update platform defaults for RHEL 8 ppc64le, RHEL 7 & 8 FIPS (x86-64)

## [0.32.0] - 2023-01-11
### Changed
- (RE-15209) Exempt github URLs from being checked as valid git repositories in order to avoid
  rate-limiting from excessive traffic.
- (RE-15095) Update git gem from 1.11.0 to 1.13.0.

### Fixed
- (maint) `only-build` option is now converted to an array so it can be used.

## [0.31.0] - 2022-10-04
### Removed
- (VANAGON-184) Remove support for Fedora 32 (x86-64)
- (VANAGON-185) Remove support for Fedora 34 (x86-64)
- (VANAGON-196) Remove support for Ubuntu 16.04 (x86 and x86-64)
- (VANAGON-197) Remove support for Debian 9 (x86 and x86-64)

### Changed
- (RE-14715) Update fustigit gem to version 0.2.0.
- (maint) osx-10-15.x86-64 installs homebrew via bash rather then ruby

## [0.30.0] - 2022-08-18
### Changed
- (maint) Update extra file signer to use rsync for extra file signing due to scp causing issues with osx.

## [0.29.0] - 2022-08-15
### Changed
- (maint) Update extra file signer to use scp and sign using a script rather than a direct ssh command.

## [0.28.0] - 2022-07-27
### Added
- (VANAGON-193) Adds support for Fedora 36 (x86-64)

### Changed
- (maint) set the Debian compat level from 7 (which is unsupported) to 10
- (maint) Fail more gently when a platform file isn't found. Also relax requirement that
  the platform name not end with the '.rb' extension.
- (maint) Update the macos hostArchitectures option to 'x86_64,arm64' in order to support the install of packages on macos M1 hardware

## [0.27.0] - 2022-06-06
### Added
- (VANAGON-182) Add Ubuntu 22.04

### Changed
- (maint) Force dh_builddeb to use -Zgzip for compatibility with reprepro. This keeps existing gzip usage and thwarts Ubuntu 22.04's desire to switch to zstd.

## [0.26.3] - 2022-05-11
### Changed
- (RE-14660) Update git gem dependency
- (maint) Simplifies logic for .tar.xz archives

## [0.26.2] - 2022-04-27
### Changed
- (maint) Add the focal-updates.list file creation and gpg key add to the provisioning step in the defaults for ubuntu-20.04-amd64

## [0.26.1] - 2022-03-29
### Added
- (VANAGON-181) Add macOS 12 Monterey x86-64 support

### Changed
- Reverted work to support Apple Notarization while we work through more issues

## [0.26.0] - 2022-03-10
### Added
- (VANAGON-179) Addition of ruby 3 support for vanagon

### Changed
- (VANAGON-187) Change valid remote repository check to use 'git ls-remote --heads' rather than 'git ls-remote'

## [0.25.0] - 2022-01-24
### Changed
- (maint) Use priority 3 for ABS and user 'vanagon' if none is given

## [0.24.0] - 2022-01-14
### Added
- (VANAGON-174) Addition 'el-9' platform
- (RE-14305) Add 'vanagon dependencies' command to generate gem dependencies as a json file
- (VANAGON-162) Added new instance variable 'log_url' to use in logs rather than the full git url
- (maint) Check environment for the X-RPROXY-PASS variable and add it to the http request header in the download method if it exists
- (maint) Allow target on CLI to set user and port

### Removed
- (VANAGON-168) Remove Fedora 30 x86_64
- (VANAGON-169) Remove Fedora 31 x86_64
- (VANAGON-170) Remove OSX 10.14 x86_64

## [0.23.0] - 2021-09-23
### Added
- (VANAGON-171) Add Ubuntu 18.04 aarch64 defaults
- (VANAGON-166) Add RedHat 8 FIPS defaults

### Changed
- (maint) Update vmpooler URL
- (VANAGON-167) Update tests to remove redhat 5

### Removed
- (VANAGON-166) Do not undefine `__debug_package` on EL 8 FIPS
- (VANAGON-177) Remove `__debug_package` workaround for EL 8

## [0.22.0] - 2021-07-06
### Added
- (PA-3709) Add Debian 11 64-bit support
- (PA-3755) add `--extended-attributes` on mac OS
- (RE-14154) Exit if `VANAGON_FORCE_SIGNING` is set

### Changed
- (maint) Update nspooler URL to reflect changed location.

## [0.21.1] - 2021-06-07
### Added
- (PA-3755) Add support for mac OS code signing
- (PA-3613) Added vanagon support for MacOS 11 Big Sur
- (VANAGON-85) Added the `clear_provisioning` method to the platform dsl to clear
  the provisioning command array.
- (maint) Added the current vanagon commands to the README.md
- (PA-3570) add the posibility to clone into a custom dirname
- (PA-3604) add Fedora 34 support
- (maint) install `libarchive` on el-8

### Changed
- (maint) `vanagon list` now returns results in alphabetical order.

## [0.21.0] - 2021-04-15
### Added
- (VANAGON-85) Moved platform definitions into core vanagon. Created default
platform definitions which projects can inherit. Added the `inherit_from_default`
method to the platform DSL. Added a `--defaults` option to `vanagon list`. This
shows all the default platforms that are available in core vanagon.

## [0.20.1] - 2021-03-15
### Changed
- (RE-13838) Remove the rescue from the ship cli code that masked Artifactory
  upload failures. Make it easier to diagnose when artifacts fail to ship.

## [0.20.0] - 2021-2-2
### Added
- (VANAGON-123) Re-add support for multiple service types for a single platform.
  This is intended primarily for Debian packages supporting both systemd and
  sysv init systems. The systemd/init check was updated.

### Fixed
- (RE-13837) Workaround a parsing bug in ruby git where Git.ls-remote was mis-parsing
  unexpected output from ssh.

## [0.19.1] - 2021-1-13
### Fixed
- (maint) Fixed an issue invoking VanagonLogger in the error handling for the
  `Vanagon::Component.load_component` method

## [0.19.0] - 2021-1-12
### Added
- (VANAGON-129) Added support for passing a version to `requires` in components
  and projects. Updated `get_requires` to handle the versions, and pass them to
  the rpm and deb packages.

### Fixed
- (VANAGON-164) Fix bugs for Solaris templates - process the OpenStruct returned
  by `get_requires`
- (maint) Fix bugs in pick_engine
- (maint) Fix pristine config files clobbering (Solaris 10)

## [0.18.1] - 2020-12-09
### Fixed
- (maint) Patch bug in engine-selection method where target argument is getting ignored
  when ABS engine is loaded.

## [0.18.0] - 2020-12-08
### Added
- (maint) Added `vanagon list` subcommand with options to list `--projects`,
  and / or `--platforms`. By default, the list is spaced with new-line
  characters. The list can be space-separated instad by specifying `--use-spaces`.
  It is possible to use `--configdir` to select a specific config directory from
  which to list the projects and or platforms.
- (maint) Added tab completion scripts for bash and zsh, located under
  /extras/completions. Also added `vanagon completion` command, which echos the
  path to the completion script. To get the path to the script, use
  `vanagon completion --shell SHELL`.Source the script to enable tab completion.
- (PA-3497) Build arm64 debian packages for aarch64

### Changed
- (VANAGON-79) Use VanagonLogger class for  output instead of puts, warn, and
  and stderr.

### Fixed
- (maint) Pristine config files are no longer kept if there are no differences
  between the pristine and the target config file (OS X and Solaris 10).
- (RE-13776) When target argument is specified, do not load the engine

### Changed
- (maint) Made 'always_be_scheduling' the default engine.

## [0.17.0] - 2020-11-02
### Added
- (DIO-1066) Update vanagon to go through ABS for VMs. Before this change,
  the ABS engine was partially implemented.
  This engine is a level of abstraction that supports any downstream
  engine (vmpooler, nspooler, AWS) and is forward compatible with
  ondemand Vmpooler pools. Used internally at Puppet

## [0.16.1] - 2020-09-18
### Fixed
- Fixed issue where the 'ship' command was failing to execute.

## [0.16.0] - 2020-09-17
### Added
- (RE-13660) Rewrote the command line parser around `docopt`. Introduced
  `vanagon <subcommand>` replacement for the existing standalone commands.
  Added deprecation warnings to the existing commands but updated them for
  temporary backwards compatibility. Integrated the standalone
  executables into a call into the new Vanagon::CLI object instead of internal
  logic.
- (VANAGON-100) Allow `--engine docker` to use `docker exec` and `docker cp`
  instead of `ssh` and `rsync` by setting `use_docker_exec true` in a
  platform definition.

### Fixed
- (VANAGON-163) Vanagon now prioritizes the `--engine` CLI flag over logic
  that picks the engine based on features used by the platform definition.

## [0.15.38] - 2020-06-16
### Fixed
- (maint) Fix for invalid build metadata JSON when generating compiled archives.
- (RE-13296) Follow redirects when installing rpm/deb repos.

### Added
- (RE-13303) Add the ability to sign additional files on windows during the MSI
build step.

## [0.15.37] - 2020-05-06
### Changed
- (maint) Build el-8 packages without build-id files to prevent collision errors.

## [0.15.36] - 2020-04-29
### Fixed
- (maint) Another el-8 debug_package fix that we missed the first time.

## [0.15.35] - 2020-04-29
### Fixed
- (RE-13396) Fix debug_package handling in el-8

## [0.15.34] - 2020-04-28
### Fixed
- (maint) Move informational output about loading inherited metadata to stderr
  instead of stdout.

## [0.15.33] - 2020-04-14
### Added
- (VANAGON-144) Add ability to load `build_metadata` from another project. This
  is useful when loading settings from another project. If you're loading settings
  via `inherit_settings` the `build_metadata` will automatically be loaded. If
  you're loading settings via `inherit_yaml_settings` you'll need to add the named
  parameter `metadata_uri` and set that to the `file://` or `http://` location
  of the upstream metadata json file.
- (VANAGON-161) Add support for setting clone options for components. This is
  set with the `clone_option` component DSL method that takes in the option name
  and value as parameters. This method can be called multiple times. This supports
  the clone options from [ruby-git](https://github.com/ruby-git/ruby-git) which
  include `bare`, `branch`, `depth`, `origin`, `path`, `remote` and `recursive`.

### Fixed
- (VANAGON-112) Fix undefined variable in warning message for version/release from git.

## [0.15.32] - 2020-02-11
### Added
- (VANAGON-155) Added `none` option to the `repo` binary so that repo can be
  called without deb or rpm packages. This will be helpful in packaging pipelines
  that do not always build deb or rpm packages.

## [0.15.31] - 2019-11-14
### Fixed
- Don't use `match?` method that wasn't added until ruby 2.4.

## [0.15.30] - 2019-11-12
### Changed
- (VANAGON-157) Make curl calls fail on error.

### Added
- Add Debian and Ubuntu platform utility matchers.
- (VANAGON-72) Give platform access to the shared `settings` hash used by the
  projects and components.

### Fixed
- (VANAGON-159) Update `parse_and_rewrite` method. It will now do no processing
  if there aren't any rewrite rules. If there are rewrite rules and you're
  specifying your git source with `git:http[...]`, this method will sub out the
  `git:` to get around some of the extra processing fustigit does to URIs.
- (VANAGON-35) Update `find_program_on_path` to support windows files with
  extensions.

## [0.15.29] - 2019-09-25
### Changed
- Loosen `is_windows?` to include windowsfips.

## [0.15.28] - 2019-09-24
### Changed
- Loosen Windows platform definition to include windowsfips.

## [0.15.27] - 2019-09-11
### Added
- Add `DEBIAN_FRONTEND=noninteractive` to apt curl install.

## [0.15.26] - 2019-09-10
### Added
- (PA-2838) Add support for windowsfips-2012r2.
- Add GitHub Action to publish gems on tag.

## [0.15.25] - 2019-07-24
### Added
- (RE-12605) Add CODEOWNERS file.

### Changed
- Rewrite `file-list-for-rpm` with perl to drastically speed up current process. If perl is not available rpmspec will fall back to using the sed loop.

### Removed
- Remove out-of-date MAINTAINERS file.

## [0.15.24] - 2019-07-08
### Changed
- (VANAGON-153) Update version in SMF manifest from the current version (which is always 1) to the puppet-runtime version since version is expected to be an integer value, per SMF documentation.
- (VANAGON-153) Update the Solaris sed to `/usr/gnu/bin/sed` which is the GNU implementation.
- (VANAGON-153) Use UNIX time for SMF version to ensure no two releases have the same version.

### Fixed
- (VANAGON-151) Update Docker engine with a 1 second sleep after each SSH failure to allow SSHD
a chance to start up before Vanagon retries the command.

## [0.15.23] - 2019-05-14
### Added
- (VANAGON-150) Allow platforms to specify `docker run` arguments.
- (PA-2670) Add support for `get_version_forced` in the vanagon component which enables
finding the version of git sources while the component is being processed.

### Fixed
- (VANAGON-101) Sanitize the docker container name so it won't contain invalid characters.

## [0.15.22] - 2019-04-04
### Changed
- (VANAGON-147) Disable shebang munging in rpm spec file.

## [0.15.21] - 2019-03-12
### Added
- (RE-12096) Set filesystem type when creating OSX packages to prevent signing
failure of osx-10.14 packages.

## [0.15.20] - 2019-02-12
### Added
- (PE-24814) Add support to handle ghostfile settings included in
the `Component::DSL` which adds them to the final rpm spec.

### Changed
- (VANAGON-132) Create metadata files with `<project>.<platform>` in the file name.
Previously `ext/build_metadata.json` now `ext/build_metadata.<project>.<platform>.json`.

## [0.15.19] - 2018-12-20
### Changed
- Moved `package_overrides` higher up in the RPM spec file to support setting
additional globals or defines that are used in the `__os_install_post`.

### Fixed
- (VANAGON-146) Simplified parsing of project vendor field for improved error
handling.

## [0.15.18] - 2018-12-10
### Added
- (PA-2231) Add support for Fedora 29 by explicitly requiring /usr/bin/touch
  and /usr/bin/mkdir when building for versions of Fedora >= 29, since core
  Fedora packages no longer provide /bin versions of these commands.

### Changed
- (VANAGON-75) Add `namespace` to `Vanagon::Patch` class so that patch files
  will not get overwritten if two different components have patch files with
  the same name.

## [0.15.17] - 2018-11-13
### Added
- (PA-1272) Add `Vanagon::Platform::OSX.install_build_dependencies` method to
  install with homebrew as a non-root user.

## [0.15.16] - 2018-11-01
### Added
- (VANAGON-122) Add `VANAGON_USE_MIRRORS` environment variable that, when set
  to 'n', will skip internal mirrors when fetching sources.

### Fixed
- Stop delivering content to the `system/volatile` directory on Solaris 11.
  Previously, package installation on Solaris 11.4 failed because this is a
  "reserved" directory.

## [0.15.15] - 2018-09-11
### Added
- (VANAGON-106) Add homepage to component DSL.
- Add `build_requirements` command to list external build requirements.

### Fixed
- (VANAGON-141) Ensure git reference defaults to HEAD.

## [0.15.14] - 2018-08-14
### Changed
-  (RE-11270) Create `ext` directory before writing build_metadata.
-  Add the --no-progress switch for choco downloads in an effort to shrink
   the size of build logs.

## [0.15.13] - 2018-07-11
### Fixed
- (VANAGON-139) Fix `retrieve_built_artifact` in the local engine to match
previous updates to the method signature.

## [0.15.12] - 2018-06-19
### Fixed
- (VANAGON-138) Fix incorrect sha1sum output when publishing yaml settings.

## [0.15.11] - 2018-06-08
### Changed
- (VANAGON-123) This work has been reverted. It was causing a regression for
  installation on debian systems using automated installers or chroots.

### Fixed
- (VANAGON-131) Paths were being incorrectly determined when inheriting yaml
  settings from a local file source.

## [0.15.10] - 2018-05-29
### Added
- (VANAGON-130) Add `publish_yaml_settings` to the project DSL to let you output
  the project's settings at build time as a yaml file.
- (VANAGON-131) Add `inherit_yaml_settings` to the project DSL to let you load
  the settings file created by `publish_yaml_settings`.

### Fixed
- A looped sed call during RPM generation was optimized.

## [0.15.9] - 2018-05-08
### Added
- (VANAGON-123) Add support for multiple service types for a single platform.
  This is intended primarily for Debian packages supporting both systemd and
  sysv init systems.

## [0.15.8] - 2018-04-17
### Fixed
- The fix for bill-of-materials in release [0.15.7] broke tar generation. This
  release fixes that issue.

## [0.15.7] - 2018-04-17
### Added
- Added task to sign packages after being built and before you ship.
Simply run `bundle exec sign`.
- Added redhatfips as an RPM platform.

### Changed
- (VANAGON-75) Fail build explicitly when patch filenames conflict.
- (VANAGON-117) Updated build help message to indicate platform/target
can be comma-separated.

### Fixed
- Previously custom BOM paths were not properly handled. When using
compiled archives, bill of materials installed in custom paths were not
removed prior to packing up the archive which could lead to conflicts
when the archive was used in other projects with custom BOM paths.
When generating the list of files to tar up, bill-of-materials was
always added. However, if project.bill_of_materials is set that file
won't exist. This change makes it conditionally add bill-of-materials
or #{proj.bill_of_materials.path}/bill-of-materials.

### Removed
- (VANAGON-117) Removed `--target` from options parser. It was added with part of the
now-removed devkit work, and any of the other subcommands that accept a
target take target as a positional parameter, so that flag is completely unused.

## [0.15.6] - 2018-03-19
### Fixed
- (VANAGON-125) On AIX, postinstall scripts for upgrades now run in
  the triggerpostun phase. This ensures they run after any postun
  scripts which can interfere with the operation of the postinstall
  scripts.
- (VANAGON-125) On AIX, service stop in postun now only runs on an
  uninstall, not on upgrades.

## [0.15.5] - 2018-03-05
### Fixed
- (VANAGON-120) Postinstall scripts for upgrades now run in the postinstall
  phase, as expected. Previously, they were run in the postuninstall phase.

## [0.15.4] - 2018-02-14
### Added
 - Added support for performing erb transforms on sources. This can be done by
   passing `erb: true` to `add_sources`.
 - `fetch_artifact` was added to the project DSL. With this, you can specify
   additional artifacts to retrieve from the builder.
 - `no_packaging` was added to the project DSL. With this, you can specify that
   you want to skip the packaging steps during the vanagon build. This is useful
   in cases where you only need to run through the build steps. `fetch_artifact`
   should be used along with `no_packaging` to pull back the build artifact
   you're looking for.
 - `release_from_git` was added to the project DSL. With this, you can set the
   project release number to be the number of commits since the last tag.

## [0.15.3] - 2018-02-06
### Changed
 - Added a runtime dependency on the packaging gem, which is required for the
   'ship' and 'repo' commands.

## [0.15.2] - 2018-01-24
### Fixed
 - RPM platform names beginning with 'redhat' were not matching the `is_rpm?`
   and `is_el?` checks.

## [0.15.1] - 2018-01-19
### Added
 - Automatic source detection can be skipped for git sources over http(s) by
   prefixing the source URL with 'git:', for example,
   'git:https://github.com/puppetlabs/vanagon'.
 - RPM platform names can now match 'redhat' in addition to 'el', 'fedora', and
   'cisco-wrlinux'.

### Changed
 - Automatic source detection for git sources now times out if `git ls-remote`
   does not return within 5 seconds. This allows us to work around an issue
   where some sources incorrectly respond to `git ls-remote` by prompting for
   a username/password even though it is not a git source. If this causes
   issues with a slower git source, you can skip the checking by specifying this
   is a git source, either by using a git url (git://github.com/puppetlabs/vanagon),
   or specifying that the http(s) source should be treated as a git source with
   the 'git:' prefix (git:http://github.com/puppetlabs/vanagon).

### Fixed
 - (VANAGON-116) Retry source fetches individually rather than retrying all if
   one fails.

## [0.15.0] - 2018-01-09
### Added
 - (VANAGON-69) Allow path for `sed` to be customized in platform definitions.
 - (VANAGON-108) Allow path and default options for `mktemp` to be customized in
   platform definitions.

### Changed
 - Updated to rubocop 0.52.1
 - RPMs were not being completely stripped of debug symbols. We weren't setting
   the correct variables in the spec file to completely strip RPMs. We've updated
   the spec file to set the correct variables for EL, SLES, and Fedora builds.
   AIX and Cisco WRLinux have had no changes to stripping at this time.

### Fixed
 - (VANAGON-34) Usage for version in `conflicts`, `replaces`, and `provides` is
   confusing. Previously the version for those settings was intended to only
   contain the version number, and then in the packaging the default comparison
   operator was added. This default was `<` for `conflicts` and `replaces`, and
   `>=` for provides. Those defaults are being maintained for the time being,
   but in the future the default will move to `=`. Those version settings should
   now be set with a comparison operator, and methods have been added to do the
   necessary munging for version comparison in Debian packages.

## [0.14.3] - 2017-12-12
### Fixed
 - In the `ship` command we need to rescue both `LoadError`s and generic
   `Exception`s to ensure the job doesn't fail on packaging < 1.0.x.

## [0.14.2] - 2017-12-12
### Fixed
 - In the `ship` binary we were incorrectly rescuing a LoadError when shipping
   to artifactory. The `rescue` has been updated to explicitly `rescue LoadError`
   since LoadError doesn't inherit from Exception.

## [0.14.1] - 2017-11-21
### Fixed
 - Remove devkit as an executable in the gemspec

## [0.14.0] - 2017-11-21 (tag-only release)
### Added
 - (VANAGON-59) Adds support for RPM and deb triggers. These can be added using
   `add_rpm_install_triggers`, `add_debian_interest_triggers`, and
   `add_debian_activate_triggers` in the component DSL.
 - (VANAGON-96) Add support for generating binary archives (gzipped tarballs)
   instead of or in addition to generating platform-native packaging. The
   project DSL now includes `generate_packages` and `generate_archives` which
   take a binary. By default projects will generate platform-native packages and
   projects will not generate binary archives.
 - (VANAGON-97) When generating binary archives, make sure the bill of materials
   (when applicable) and generated build metadata are included in the build
   output.
 - (VANAGON-76) Implement a more flexible `--preserve` flag. `--preserve` now
   supports `always`, `never`, and `on-failure`. Default behavior of preserving
   on failure has been maintained, and `--preserve` with no additional arguments
   is equivalent to `--preserve always`.
 - (VANAGON-99) Add `install_only` to the component dsl to make it easier to
   consume artifacts generated via `generate_archives`.
 - (VANAGON-111) When using `generate_archives`, generate a sha1sum at build
   time. To enable this, `shasum` has been added to the platform DSL for
   specifying alternate paths for the sha1sum command.
 - (VANAGON-111) Enable consumption of remote checksums. Each of the supported
   component checksums (sha1sum, md5sum, sha256sum, sha512sum) can now either
   take a checksum or a URL where the checksum can be found.
 - Add `archive` package type for windows so you can generate an archive without
   needing to generate WIX or nuget artifacts.
 - Add nspooler support to the pooler engine.
 - (VANAGON-110) Add support for inheriting the project hash from an upstream
   project. `inherit_settings` has been added to the project DSL for this.

### Fixed
 - Avoid duplicate file warnings when RPMs have files containing spaces in their
   path.
 - Print backtrace if the command executed in `retry_with_timeout` fails.

### Changed
 - The `mirrors` list will no longer include the source URI so you don't end up
   hitting the upstream source instead of the configured mirrors.
 - Updated to pull from github.com/puppetlabs/packaging 1.0.x branch to enable
   shipping artifacts to artifactory in addition to the internal build server.

### Removed
 - The `devkit` command has been removed since much of its initial functionality
   has been built into `build`, `render`, and `inspect`.

## [0.13.1] - 2017-07-19
### Added
 - Component Url is now reported in the `build_metadata.json` file.

## [0.13.0] - 2017-07-12
### Added
 - A metadata file is generated when producing artifacts which contains
   metadata about components and various other information about a built
   artifact. This new file will exist at `ext/build_metadata.json` and contains
   the version of Vanagon which built the last artifact, a timestamp of when
   the artifact was created, the version of the artifact that was built, and a
   list of components with their version information which make up the built
   artifact.

## [0.12.2] - 2017-06-29
### Fixes
- Previously, we created AIX services once at install, but did not have
  correct logic to update them if they changed. This release adds the necessary
  logic to reconfigure AIX services.

## [0.12.1] - 2017-06-12
### Fixes
- install_file was not respecting file mode, which was causing problems with
  file permissions on platforms like MacOS that do not explicitly manage permissions
  in the packaging. This should now be fixed for those cases, with the exception of
  Windows MSI packaging, that still needs to be managed in the WIX files.

## [0.12.0] - 2017-05-31
### Added
- Added `generate_source_artifacts` method to the platform dsl to allow generation
  of `.src.rpm` and debian source artifacts.
- Added support to the Component DSL for Mirror URLs using the `#mirror` method. This functionality supersedes the previous Rewrite Rule functionality and the Rewrite Rule functionality has been deprecated (see *Deprecated* for `0.12.0`).
  Vanagon will attempt to use any Mirror URLs provided for a component before it attempts to use the canonical upstream URL. Multiple Mirror URLs can be specified, and Vanagon will attempt to retrieve them in random order until a URL returns a `200` code or all Mirror URLs are exhausted.
  For examples of mirrors in use, see the [example project](examples/projects/project.rb) and [component](examples/components/component2.rb).

### Deprecated
- The Component DSL Rewrite Engine is deprecated in favor of Component DSL Mirror URLs. Existing Rewrite Rules will be converted to Mirror URLs and added to the Mirror URL list. The Component DSL Rewrite Engine will be removed before Vanagon 1.0.0 is released.

### Changed
- Updated to sending notification messages on STDERR instead of STDOUT. This both enables easier filtering and helps with some of the fragility around commands expecting formatted output on STDOUT. For more context around this see the [ticket](https://tickets.puppetlabs.com/browse/VANAGON-57) and [pull request](https://github.com/puppetlabs/vanagon/pull/474).

### Fixes
- Exceptions now provide accurate backtraces if thrown while parsing Component, Platform, or Projects.

## [0.11.3] - 2017-04-10
### Changed
- Removed dependency on files `/bin/touch` and `/bin/mkdir` for any RPMs generated for AIX platforms.
- If the `workdir` path is underneath a symbolically linked path, Vanagon will now resolve the complete path instead of using the symbolically linked path.
- Vanagon no longer creates backup copies of any source files patched during the staging process.

## [0.11.2] - 2017-04-04
### Added
- Added the `link_target` keyword argument to `install_service`. If `link_target` is specified, instead of installing the `service_file` in the platform/init system default for service files, the file will be installed to the `link_target` and a link will be added from the system's default for service files to the link target.

## [0.11.1] - 2017-03-30
### Fixed
- Dirname now honors when user overrides the default directory a source unpacks into

### Changed
- Update git tests to no longer hit the network and run quite a bit faster

## [0.11.0] - 2017-03-22
### Added
- A new Platform DSL method, `shell`, has been added. This allows a user to define a custom shell or path to a specific shell for a given platform.
- Support for specifying the owner, group, and permission mode has been added to the Component DSL.

### Fixed
- Fixed many bugs in the handling of component environment variables. Rendering them as [target-specific variables](https://www.gnu.org/software/make/manual/html_node/Target_002dspecific.html) in a project's Makefile introduced a number of bugs in many Vanagon projects due to target-specific variables being transitive between dependent Make targets.

### Changed
- All defined Project and Platform environment variables are rendered as [Make variables](https://www.gnu.org/software/make/manual/html_node/Using-Variables.html). Specifically, as "[Simply expanded variables](https://www.gnu.org/software/make/manual/html_node/Flavors.html#Flavors)".
- All defined Component environment variables will be rendered as Make variables. This means that escaped literals (`$$VARIABLE_NAME`) and subshells (`$$(echo "I'm a subshell")`) will now be converted to their Makefile equivalents: `$(VARIABLE_NAME)` and `$(shell echo "I'm a subshell")` and Vanagon will emit a deprecation notice for these values. The goal is to provide a single target for formatting environment variables in an effort to make behavior more deterministic.
- The `build` command line flag, `--remote_workdir`, has been renamed to `--remote-workdir`. This flag allows users to specify a directory on the remote build target for Vanagon to stage components & metadata under when compiling.

### Removed
- We've removed initial support for metrics collection. The functionality depended on Make's usage of target-specific variables, so if they're unreliable (and they are) then the metrics functionality is also unreliable. Consider instead using [Remake](http://bashdb.sourceforge.net/remake/) if you need to profile a Vanagon build. We may provide official support for `remake --profile` in a future Vanagon release.

## [0.10.0] - 2017-02-21
### Added
- Initial support to the Makefile to enable metrics collection during a build
- Allow user to specify the directory on the build host to place sources and
  perform build tasks to allow for faster iteration

### Changed
- Overhaul of how vanagon handles environment variables. Vanagon now has an
  environment class that allows users to scope environment variables to be
  project specific, platform specific, or component specific
- Allow `dist` tag used in naming rpm packages to be specified

## [0.9.3] - 2017-03-01
### Added
- Allow user to specify the directory on the build host to place sources and
  perform build tasks to allow for faster iteration.
- Add support for linking directories during the install step. Prior to this,
  if you did an `ln -s sourcedir targetdir` file list autogeneration would fail
  since we were following symlinks. We now do not follow symlinks when
  generating the file lists.
- Add support for setting `owner`, `group` and `mode` for configfiles. This
  functionality already existed for `install_file` but was missing for
  `install_configfile`.
- Allow `dist` tag used in naming rpm packages to be specified.

## [0.9.2] - 2017-01-31
### Added
- Experimental `render` command added to aid in rapid Makefile iteration and testing

### Deprecated
- is_osx? method deprecated in favor of is_macos? ([VANAGON-28](https://tickets/puppetlabs.com/browse/VANAGON-28))

### Changed
- Updated to Rubocop 0.47.x
- MAINTAINERS file updated with current project maintainers

## [0.9.1] - 2017-01-09
This is a bug-fix release to replace the yanked 0.9.0 release.

### Fixed
- The DSL code underneath the Component source checksums was refactored in
  0.9.0. Tests passed, but the code was broken. Upon triage we discovered
  that those code paths were never well tested to begin with, which is how
  the bug was missed. The DSL code paths in question have been improved,
  and the bug has been corrected.
- We sanitize the `ENV` hash further while testing token support in the
  vmpooler engine.

## [0.9.0] - 2017-01-06; yanked on 2017-01-06
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

[Unreleased]: https://github.com/puppetlabs/vanagon/compare/0.52.0...HEAD
[0.52.0]: https://github.com/puppetlabs/vanagon/compare/0.51.0...0.52.0
[0.51.0]: https://github.com/puppetlabs/vanagon/compare/0.50.0...0.51.0
[0.50.0]: https://github.com/puppetlabs/vanagon/compare/0.49.0...0.50.0
[0.49.0]: https://github.com/puppetlabs/vanagon/compare/0.48.0...0.49.0
[0.48.0]: https://github.com/puppetlabs/vanagon/compare/0.47.0...0.48.0
[0.47.0]: https://github.com/puppetlabs/vanagon/compare/0.46.0...0.47.0
[0.46.0]: https://github.com/puppetlabs/vanagon/compare/0.45.0...0.46.0
[0.45.0]: https://github.com/puppetlabs/vanagon/compare/0.44.0...0.45.0
[0.44.0]: https://github.com/puppetlabs/vanagon/compare/0.43.0...0.44.0
[0.43.0]: https://github.com/puppetlabs/vanagon/compare/0.42.0...0.43.0
[0.42.0]: https://github.com/puppetlabs/vanagon/compare/0.41.0...0.42.0
[0.41.0]: https://github.com/puppetlabs/vanagon/compare/0.40.0...0.41.0
[0.40.0]: https://github.com/puppetlabs/vanagon/compare/0.39.3...0.40.0
[0.39.3]: https://github.com/puppetlabs/vanagon/compare/0.39.2...0.39.3
[0.39.2]: https://github.com/puppetlabs/vanagon/compare/0.39.1...0.39.2
[0.39.1]: https://github.com/puppetlabs/vanagon/compare/0.39.0...0.39.1
[0.39.0]: https://github.com/puppetlabs/vanagon/compare/0.38.0...0.39.0
[0.38.0]: https://github.com/puppetlabs/vanagon/compare/0.37.1...0.38.0
[0.37.1]: https://github.com/puppetlabs/vanagon/compare/0.37.0...0.37.1
[0.37.0]: https://github.com/puppetlabs/vanagon/compare/0.36.0...0.37.0
[0.36.0]: https://github.com/puppetlabs/vanagon/compare/0.35.1...0.36.0
[0.35.1]: https://github.com/puppetlabs/vanagon/compare/0.35.0...0.35.1
[0.35.0]: https://github.com/puppetlabs/vanagon/compare/0.34.0...0.35.0
[0.34.0]: https://github.com/puppetlabs/vanagon/compare/0.33.0...0.34.0
[0.33.0]: https://github.com/puppetlabs/vanagon/compare/0.32.0...0.33.0
[0.32.0]: https://github.com/puppetlabs/vanagon/compare/0.31.0...0.32.0
[0.31.0]: https://github.com/puppetlabs/vanagon/compare/0.30.0...0.31.0
[0.30.0]: https://github.com/puppetlabs/vanagon/compare/0.29.0...0.30.0
[0.29.0]: https://github.com/puppetlabs/vanagon/compare/0.28.0...0.29.0
[0.28.0]: https://github.com/puppetlabs/vanagon/compare/0.27.0...0.28.0
[0.27.0]: https://github.com/puppetlabs/vanagon/compare/0.26.3...0.27.0
[0.26.3]: https://github.com/puppetlabs/vanagon/compare/0.26.2...0.26.3
[0.26.2]: https://github.com/puppetlabs/vanagon/compare/0.26.1...0.26.2
[0.26.1]: https://github.com/puppetlabs/vanagon/compare/0.26.0...0.26.1
[0.26.0]: https://github.com/puppetlabs/vanagon/compare/0.25.0...0.26.0
[0.25.0]: https://github.com/puppetlabs/vanagon/compare/0.24.0...0.25.0
[0.24.0]: https://github.com/puppetlabs/vanagon/compare/0.23.0...0.24.0
[0.23.0]: https://github.com/puppetlabs/vanagon/compare/0.22.0...0.23.0
[0.22.0]: https://github.com/puppetlabs/vanagon/compare/0.21.1...0.22.0
[0.21.1]: https://github.com/puppetlabs/vanagon/compare/0.21.0...0.21.1
[0.21.0]: https://github.com/puppetlabs/vanagon/compare/0.20.1...0.21.0
[0.20.1]: https://github.com/puppetlabs/vanagon/compare/0.20.0...0.20.1
[0.20.0]: https://github.com/puppetlabs/vanagon/compare/0.19.1...0.20.0
[0.19.1]: https://github.com/puppetlabs/vanagon/compare/0.19.0...0.19.1
[0.19.0]: https://github.com/puppetlabs/vanagon/compare/0.18.1...0.19.0
[0.18.1]: https://github.com/puppetlabs/vanagon/compare/0.18.0...0.18.1
[0.18.0]: https://github.com/puppetlabs/vanagon/compare/0.17.0...0.18.0
[0.17.0]: https://github.com/puppetlabs/vanagon/compare/0.16.1...0.17.0
[0.16.1]: https://github.com/puppetlabs/vanagon/compare/0.16.0...0.16.1
[0.16.0]: https://github.com/puppetlabs/vanagon/compare/0.15.38...0.16.0
[0.15.38]: https://github.com/puppetlabs/vanagon/compare/0.15.37...0.15.38
[0.15.37]: https://github.com/puppetlabs/vanagon/compare/0.15.36...0.15.37
[0.15.36]: https://github.com/puppetlabs/vanagon/compare/0.15.35...0.15.36
[0.15.35]: https://github.com/puppetlabs/vanagon/compare/0.15.34...0.15.35
[0.15.34]: https://github.com/puppetlabs/vanagon/compare/0.15.33...0.15.34
[0.15.33]: https://github.com/puppetlabs/vanagon/compare/0.15.32...0.15.33
[0.15.32]: https://github.com/puppetlabs/vanagon/compare/0.15.31...0.15.32
[0.15.31]: https://github.com/puppetlabs/vanagon/compare/0.15.30...0.15.31
[0.15.30]: https://github.com/puppetlabs/vanagon/compare/0.15.29...0.15.30
[0.15.29]: https://github.com/puppetlabs/vanagon/compare/0.15.28...0.15.29
[0.15.28]: https://github.com/puppetlabs/vanagon/compare/0.15.27...0.15.28
[0.15.27]: https://github.com/puppetlabs/vanagon/compare/0.15.26...0.15.27
[0.15.26]: https://github.com/puppetlabs/vanagon/compare/0.15.25...0.15.26
[0.15.25]: https://github.com/puppetlabs/vanagon/compare/0.15.24...0.15.25
[0.15.24]: https://github.com/puppetlabs/vanagon/compare/0.15.23...0.15.24
[0.15.23]: https://github.com/puppetlabs/vanagon/compare/0.15.22...0.15.23
[0.15.22]: https://github.com/puppetlabs/vanagon/compare/0.15.21...0.15.22
[0.15.21]: https://github.com/puppetlabs/vanagon/compare/0.15.20...0.15.21
[0.15.20]: https://github.com/puppetlabs/vanagon/compare/0.15.19...0.15.20
[0.15.19]: https://github.com/puppetlabs/vanagon/compare/0.15.18...0.15.19
[0.15.18]: https://github.com/puppetlabs/vanagon/compare/0.15.17...0.15.18
[0.15.17]: https://github.com/puppetlabs/vanagon/compare/0.15.16...0.15.17
[0.15.16]: https://github.com/puppetlabs/vanagon/compare/0.15.15...0.15.16
[0.15.15]: https://github.com/puppetlabs/vanagon/compare/0.15.14...0.15.15
[0.15.14]: https://github.com/puppetlabs/vanagon/compare/0.15.13...0.15.14
[0.15.13]: https://github.com/puppetlabs/vanagon/compare/0.15.12...0.15.13
[0.15.12]: https://github.com/puppetlabs/vanagon/compare/0.15.11...0.15.12
[0.15.11]: https://github.com/puppetlabs/vanagon/compare/0.15.10...0.15.11
[0.15.10]: https://github.com/puppetlabs/vanagon/compare/0.15.9...0.15.10
[0.15.9]: https://github.com/puppetlabs/vanagon/compare/0.15.8...0.15.9
[0.15.8]: https://github.com/puppetlabs/vanagon/compare/0.15.7...0.15.8
[0.15.7]: https://github.com/puppetlabs/vanagon/compare/0.15.6...0.15.7
[0.15.6]: https://github.com/puppetlabs/vanagon/compare/0.15.5...0.15.6
[0.15.5]: https://github.com/puppetlabs/vanagon/compare/0.15.4...0.15.5
[0.15.4]: https://github.com/puppetlabs/vanagon/compare/0.15.3...0.15.4
[0.15.3]: https://github.com/puppetlabs/vanagon/compare/0.15.2...0.15.3
[0.15.2]: https://github.com/puppetlabs/vanagon/compare/0.15.1...0.15.2
[0.15.1]: https://github.com/puppetlabs/vanagon/compare/0.15.0...0.15.1
[0.15.0]: https://github.com/puppetlabs/vanagon/compare/0.14.3...0.15.0
[0.14.3]: https://github.com/puppetlabs/vanagon/compare/0.14.2...0.14.3
[0.14.2]: https://github.com/puppetlabs/vanagon/compare/0.14.1...0.14.2
[0.14.1]: https://github.com/puppetlabs/vanagon/compare/0.14.0...0.14.1
[0.14.0]: https://github.com/puppetlabs/vanagon/compare/0.13.1...0.14.0
[0.13.1]: https://github.com/puppetlabs/vanagon/compare/0.13.0...0.13.1
[0.13.0]: https://github.com/puppetlabs/vanagon/compare/0.12.2...0.13.0
[0.12.2]: https://github.com/puppetlabs/vanagon/compare/0.12.1...0.12.2
[0.12.1]: https://github.com/puppetlabs/vanagon/compare/0.12.0...0.12.1
[0.12.0]: https://github.com/puppetlabs/vanagon/compare/0.11.3...0.12.0
[0.11.3]: https://github.com/puppetlabs/vanagon/compare/0.11.2...0.11.3
[0.11.2]: https://github.com/puppetlabs/vanagon/compare/0.11.1...0.11.2
[0.11.1]: https://github.com/puppetlabs/vanagon/compare/0.11.0...0.11.1
[0.11.0]: https://github.com/puppetlabs/vanagon/compare/0.10.0...0.11.0
[0.10.0]: https://github.com/puppetlabs/vanagon/compare/0.9.2...0.10.0
[0.9.3]: https://github.com/puppetlabs/vanagon/compare/0.9.2...0.9.3
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
