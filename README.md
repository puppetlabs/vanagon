![Build Status](https://travis-ci.org/puppetlabs/vanagon.svg?branch=master)
The Vanagon Project
===
 * What is vanagon?
 * Runtime requirements
 * Configuration and Usage
 * Overview
 * Contributing
 * License
 * Maintainers
 * Support

What is vanagon?
---
Vanagon is a tool to build a single package out of a project, which can itself
contain one or more components. This tooling is being used to develop the
puppet-agent package, which contains components such as openssl, ruby, and
augeas among others. For a simple example, please see the examples directory.

Vanagon builds up a Makefile and packaging files (specfile for RPM,
control/rules/etc for DEB) and copies them to a remote host, where make can be
invoked to build all of the components and make a package of the contents.

Vanagon also provides a devkit command that will prepare a machine as a
development environment for the entire project, or restricted to individual
components of the project. The devkit command installs all required build tools,
creates a master makefile for the project, and configures, builds, and installs
all components. The result is an environment where you can work on individual
components, then rebuild the project and test the installed artifacts.

Runtime Requirements
---
Vanagon is self-contained. A recent version of ruby (2.1 or greater) should be
all that is required. Beyond that, ssh, rsync and git are also required on the
host, and ssh-server and rsync is required on the target (package installation
for the target can be customized in the platform config for the target).

Configuration and Usage
---
Vanagon won't be much use without a project to build. Beyond that, you must
define any platforms you want to build for. Vanagon ships with some simple
binaries to use, but the one you probably care about is named 'build'.

### `build` usage

The build command has positional arguments and position independent flags.

#### Arguments (position dependent)

##### project name
The name of the project to build, and a file named \<project\_name\>.rb must be
present in configs/projects in the working directory.

##### platform name
The name of the platform to build against, and a file named
\<platform\_name\>.rb must be present in configs/platforms in the working
directory.

Platform can also be a comma separated list of platforms such as platform1,platform2.

##### target host [optional]
Target host is an optional argument to override the host selection. Instead of using
a vm collected from the pooler, the build will attempt to ssh to target as the
root user.

If building on multiple platforms, multiple targets can also be specified using
a comma separated list such as host1,host2. If less targets are specified than
platforms, the default engine (the pooler) will be used for platforms without a
target. If more targets are specified than platforms, the extra will be ignored.

#### Flagged arguments (can be anywhere in the command)

##### -w DIR, --workdir DIR
Specifies a directory where the sources should be placed and builds performed.
Defaults to a temporary directory created with Ruby's Dir.mktmpdir.

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

#### Flags (can be anywhere in the command)

##### -p, --preserve
Indicates that the host used for building the project should be left intact
after the build instead of destroyed. The host is usually destroyed after a
successful build, or left after a failed build.

##### -v, --verbose (not yet implemented)
Increase verbosity of output.

##### -h, --help
Display command-line help.

#### Environment variables

##### VANAGON\_SSH\_KEY
A full path on disk for a private ssh key to be used in ssh and rsync
communications. This will be used instead of whatever defaults are configured
in .ssh/config.

##### VANAGON\_SSH\_AGENT
When set, Vanagon will forward the ssh authentication agent connection.

##### VMPOOLER\_TOKEN
Used in conjunction with the pooler engine, this is a token to pass to the
vmpooler to access the API. Without this token, the default lifetime of vms
will be much shorter.

##### LOCK\_MANAGER\_HOST
The name of the host where redis is running. Redis is used to handle a lock
when using the hardware engine. It defaults to *redis*, with no domain.

#### LOCK\_MANAGER\_PORT
Port of the system where redis is running. Defaults to *6379*.

#### Example usage
`build --preserve puppet-agent el-6-i386` will build the puppet-agent project
on the el-6-i386 platform and leave the host intact afterward.

`build --engine=docker puppet-agent el-6-i386` will build the puppet-agent
project on the el-6-i386 platform using the docker engine (the platform must
have a docker\_image defined in its config).

### `devkit` usage

The devkit command has positional arguments and position independent flagged
arguments.

#### Arguments (position dependent)

##### project name
As in `build` arguments.

##### platform name
As in `build` arguments.

##### component names [optional]
Specifies specific components that should be built. If components are not
specified, then all components in the project will be built. If components
are specified as arguments, then any in the project that aren't specified
as arguments will be retrieved from packages rather than built from source.

#### Flagged arguments (can be anywhere in the command)

Supports all flagged arguments from the `build` command.

##### -t HOST, --target HOST
As in the `build` target host optional argument.

#### Flags (can be anywhere in the command)

##### -h, --help
Display command-line help.

Engines
---

### Amazon Ec2

Note: If you have the `aws_ami` setup vanagon will default to the ec2 engine.

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
[examples](https://github.com/puppetlabs/vanagon/tree/master/examples) directory and the YARD documentation for vanagon.

## Maintainers
---
The Release Engineering team at Puppet Labs

Maintainer: Michael Stahnke <stahnma@puppet.com>

Please log tickets and issues at our [Issue Tracker](https://tickets.puppet.com/browse/CPR). Set compononent to Vanagon.

In addition there is an active #puppet-dev channel on Freenode.
