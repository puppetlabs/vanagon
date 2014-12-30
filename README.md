The Vanagon Project
===
 * What is vanagon?
 * Runtime requirements
 * Configuration and Usage
 * Overview
 * License
 * Maintainers

What is vanagon?
---
Vanagon is a tool to build a single package out of a project, which can itself
contain one or more components. This tooling is being used to develop the
puppet-agent package, which contains components such as openssl, ruby, and
augeas among others. For a simple example, please see the examples directory.

Vanagon builds up a Makefile and packaging files (specfile for RPM,
control/rules/etc for DEB) and copies them to a remote host, where make can be
invoked to build all of the components and make a package of the contents.

Runtime Requirements
---
Vanagon is self-contained. A recent version of ruby should be all that is
required. Beyond that, ssh, rsync and git are also required on the host, and
ssh-server and rsync is required on the target (package installation for the
target can be customized in the platform config for the target).

Configuration and Usage
---
Vanagon won't be much use without a project to build. Beyond that, you must
define any platforms you want to build for. Vanagon ships with some simple
binaries to use, but the one you probably care about is named 'build'.

License
---
See [LICENSE](LICENSE) file.

Overview
---
Vanagon is broken down into three core ideas: the project, the component and
the platform. The project contains one or more components and is built for a
platform. As a quick example, if I had a ruby app and wanted to package it, the
project would probably contain a component for ruby and a component for my app.
If I wanted to build it for debian wheezy, I would define a platform called
wheezy and build my project against it.

For more detailed examples of the DSLs available, please see the
[examples](examples) directory and the YARD documentation for vanagon.

Maintainers
---
The Release Engineering team at Puppet Labs
