![Build Status](https://travis-ci.org/puppetlabs/vanagon.svg?branch=master)
# The Vanagon Project

<!-- MarkdownTOC -->

- [What is Vanagon?](#what-is-vanagon)
  - [How is it pronounced?](#how-is-it-pronounced)
- [Runtime Requirements](#runtime-requirements)
  - [Local Host:](#local-host)
  - [Remote Build Target:](#remote-build-target)
- [Configuration and Usage](#configuration-and-usage)
  - [`build` usage](#build-usage)
  - [`inspect` usage](#inspect-usage)
- [Engines](#engines)
  - [Amazon Ec2](#amazon-ec2)
- [Contributing](#contributing)
- [License](#license)
- [Overview](#overview)
- [Maintainers](#maintainers)

<!-- /MarkdownTOC -->


## What is Vanagon?

Vanagon is a tool to build a single package out of a project, which can itself
contain one or more components. This tooling is being used to develop the
puppet-agent package, which contains components such as openssl, ruby, and
augeas among others. For a simple example, please see the project in the `examples/` directory.

Vanagon builds up a Makefile and packaging files (specfile for RPM,
control/rules/etc for DEB) and copies them to a remote host, where make can be
invoked to build all of the components and make a package of the contents.

### How is it pronounced?

Vanagon (/ˈvænəgɪn/) sounds like "van again." It does not sound like "van wagon" or "van and gone."

## Runtime Requirements

Vanagon carries two sets of requirements: requirements for the local host where Vanagon is run, and for the remote target where compilation and packaging happens.

Also, Vanagon ships with a number of engines which may include additional optional dependencies if you wish to use them. These engines are currently considered experimental, and receive less attention than the `Hardware` or `vmpooler` engines do. If you find a bug in these engines, [please open a ticket](https://tickets.puppetlabs.com/browse/PA) and let us know.

### Local Host:

- [Ruby](https://www.ruby-lang.org/en/) (Ruby 2.1.x is the miniumum supported version)
- [fustigit](https://github.com/mckern/fustigit)
- [ruby-git](https://github.com/schacon/ruby-git)
- The command line tool `ssh` ([homepage](https://www.openssh.com/)) available on the local `${PATH}` (any modern version should suffice)
- The command line tool `rsync` ([homepage](https://rsync.samba.org/)) available on the local `${PATH}` (At least rsync 2.6.x)
- The command line tool `git` ([homepage](https://git-scm.com/)) available on the local `${PATH}` (Vanagon is tested against Git version 1.8.x but should work with any newer version)

#### Optional requirements

- [AWS SDK for Ruby](https://github.com/aws/aws-sdk-ruby), if you're using the EC2 engine
- [Docker](https://www.docker.com/community-edition), if you're using the Docker engine

### Remote Build Target:

**Note:** package installation & builder configuration for the remote target can be customized in the `Platform` configuration that defines target provisioning instructions.

- GNU Make ([homepage](https://www.gnu.org/software/make/)) (Vanagon specifically targets the feature set provided by [GNU Make 3.81](http://git.savannah.gnu.org/cgit/make.git/tree/NEWS?h=3.81&id=776d8b7bc2ff83f8ebf5d357ec89e3bbe6d83962) but newer versions are known to work -- older versions are specifically known to **not** work!)
- Bash ([homepage](https://www.gnu.org/software/bash/)) is required by the Makefiles that Vanagon generates
- An ssh server ([homepage](https://www.openssh.com/)) is required by most engines
- The command line tool `rsync` ([homepage](https://rsync.samba.org/)) (At least rsync 2.6.x)

## Configuration and Usage

Vanagon won't be much use without a project to build. Beyond that, you must
define any platforms you want to build for. Vanagon ships with some simple
binaries to use, but the one you probably care about is named 'build'.

### `build` usage
The build command has positional arguments and position independent flags.

#### Arguments (position dependent)

##### project name
The name of the project to build; a file named `<project_name>.rb` must be
present under `configs/projects` in the working directory.

##### platform name
The name of the target platform to build `<project_name>` against; a file named
`<platform_name>.rb` must be present under `configs/platforms` in the working
directory. This can also be a comma separated list of platforms such as `platform1,platform2`;
note that there are no spaces after the comma.

##### target host <optional>
Target host is an optional argument to override the host selection. Instead of using
a random VM collected from the pooler (Vanagon's default build engine), the build will
attempt connect to the target host over SSH as the `root` user.

If building on multiple platforms, multiple targets can also be specified using
a comma separated list such as `host1,host2` (note that there are no spaces after
the comma). If less targets are specified than platforms, the default engine
(`pooler`) will be used for platforms without a target. If more targets are specified
than platforms, the extra platforms will be ignored.

Build machines should be cleaned between builds.

#### Flagged arguments

**Note:** command flags can be used anywhere in the command.

##### -w DIR, --workdir DIR
Specifies a directory on the local host where the sources should be placed and builds performed.
Defaults to a temporary directory created with Ruby's `Dir.mktmpdir` method.

##### -r DIR, --remote-workdir DIR
Explicitly specify a directory on the remote target to place sources and perform
builds. Components can then be rebuilt manually on the build host for faster iteration. Sources may not be correctly updated if this directory already exists.
Defaults to a temporary directory created by running `mktemp -d` on the remote target.

##### -c DIR, --configdir DIR
Specifies where project configuration is found. Defaults to $pwd/configs.

##### -e ENGINE, --engine ENGINE
Choose a different virtualization engine to use to select the build target.
Currently supported engines are:
* `base` - Pure ssh backend; no teardown currently defined
* `local` - Build on the local machine; platform name must match the local machine
* `docker` - Builds in a docker container
* `pooler` - Selects a vm from Puppet Labs' vm pooler to build on
* `hardware` - Build on a specific taget and lock it in redis
* `ec2` - Build on a specific AWS instance.

#### Flags

**Note:** command flags can be used anywhere in the command.

##### -p, --preserve
Indicates that the host used for building the project should be left intact
after the build instead of destroyed. The host is usually destroyed after a
successful build, or left after a failed build.

##### -v, --verbose
(Reserved for future implementation) Will increase the verbosity of output, when implemented.

##### -h, --help
Display command-line help.


#### Environment variables

##### `VANAGON_SSH_KEY`
A full path on disk for a private ssh key to be used in ssh and rsync
communications. This will be used instead of whatever defaults are configured
in .ssh/config.

##### `VANAGON_SSH_AGENT`
When set, Vanagon will forward the ssh authentication agent connection.

##### `VMPOOLER_TOKEN`
Used in conjunction with the pooler engine, this is a token to pass to the
vmpooler to access the API. Without this token, the default lifetime of vms
will be much shorter.

##### `LOCK_MANAGER_HOST`
The name of the host where redis is running. Redis is used to handle a lock
when using the hardware engine. It defaults to *redis*, with no domain.

##### `LOCK_MANAGER_PORT`
Port of the system where redis is running. Defaults to *6379*.

##### `VANAGON_RETRY_COUNT`
Some phases of compilation support retries. The default value is *1* but
setting to any integer value greater than 1 will causes these components
to retry operations on failure until the `VANAGON_RETRY_COUNT` limit is reached.

##### `VANAGON_TIMEOUT`
Some phases of compilation can take an indeterminate (but substantial) amount of
time. The default value is *7200* seconds(120 minutes) but setting to any
integer value these components to fail after the `VANAGON_TIMEOUT` count is reached.
Note that this value is expected to be in seconds.

#### Example usage
`build --preserve puppet-agent el-6-i386` will build the puppet-agent project
on the el-6-i386 platform and leave the host intact afterward.

`build --engine=docker puppet-agent el-6-i386` will build the puppet-agent
project on the el-6-i386 platform using the docker engine (the platform must
have a docker\_image defined in its config).

---

### `inspect` usage

The `inspect` command has positional arguments and position independent flags. It
mirrors the `build` command, but exits with success after loading and interpolating
all of the components in the given project. No attempt is made to actually build
the given project; instead, a JSON formatted array of hashes is returned and printed
to `stdout`. This JSON array can be further processed by external tooling, such as `jq`.

#### Arguments (position dependent)

##### project name
The name of the project to build, and a file named \<project\_name\>.rb must be
present in configs/projects in the working directory.

##### platform name
The name of the platform to build against, and a file named
\<platform\_name\>.rb must be present in configs/platforms in the working
directory.

Platform can also be a comma separated list of platforms such as platform1,platform2.

#### Flagged arguments

**Note:** command flags can be used anywhere in the command.

##### -w DIR, --workdir DIR
Specifies a directory where the sources should be placed and builds performed.
Defaults to a temporary directory created with Ruby's Dir.mktmpdir.

##### -c DIR, --configdir DIR <optional>
Specifies where project configuration is found. Defaults to $pwd/configs.

##### -e ENGINE, --engine ENGINE
Choose a different virtualization engine to use to select the build target.
Engines are respected, but only insofar as components and projects are
rendered -- the `inspect` command performs no compilation.

Supported engines are the same as the `build` command.

#### Flags

**Note:** command flags can be used anywhere in the command.

##### -v, --verbose (not yet implemented)
Increase verbosity of output.

##### -h, --help
Display command-line help.

#### Environment variables

Environment variables are respected, but only insofar as components and projects are
rendered -- the `inspect` command has no behavior to alter.

Supported environment variables are the same as the `build` command.

#### Example usage
`inspect puppet-agent el-6-i386` will load the puppet-agent project
on the el-6-i386 platform and print the resulting list of dependencies,
build-time configuration, environment variables, and expected artifacts.

---

Engines
---

### Amazon Ec2

Note: If you have the `aws_ami` setup Vanagon will default to the ec2 engine.

To use the ec2 engine you should have your credentials set either via your `~/.aws/credentials` or environment variables.
After this you can setup your `configs/platforms/<platform>.rb` to use your
ami, instance type, and key_name to setup the instance.

A simple one looks like this

```ruby
# configs/platforms/el-7-x86_64.rb
platform "el-7-x86_64" do |plat|
    plat.aws_ami "your-ami-id-here" # You must set this
    plat.aws_instance_type "t2.small" # Defaults to t1.micro
    plat.aws_key_name "vanagon" # this is the default but you can use whichever
    plat.aws_user_data <<-eos
#cloud-config
    runcmds:
        - echo #{my_ssh_key} > /root/.ssh/authorized_keys # Most amis block you from logging in as root.
    eos

### Rest of your code here

end
```


Contributing
---
We'd love to get contributions from you! Once you are up and running, take a look at the
[Contribution Documents](https://github.com/puppetlabs/vanagon/blob/master/docs/CONTRIBUTING.md) to see how to get your changes merged
in.

License
---
See [LICENSE](https://github.com/puppetlabs/vanagon/blob/master/LICENSE) file.

Overview
---
Vanagon is broken down into three core ideas: the project, the component and
the platform. The project contains one or more components and is built for a
platform. As a quick example, if I had a ruby app and wanted to package it, the
project would probably contain a component for ruby and a component for my app.
If I wanted to build it for debian wheezy, I would define a platform called
wheezy and build my project against it.

For more detailed examples of the DSLs available, please see the
[examples](https://github.com/puppetlabs/vanagon/tree/master/examples) directory and the YARD documentation for Vanagon.

## Maintainers
See MAINTAINERS file.
