# Using Vanagon
- Note that these docs are incomplete. Docs for all parts of vanagon are on their way

## Creating a Vanagon Project for Windows

### Overview
Vanagon projects for windows use [WiX](http://wixtoolset.org/) to create MSIs that will install on native windows platforms.  Vanagon uses the same process between all platforms, including windows, to build and stage artifacts before creating an installer.  Vanagon only uses WiX files for the actual installer itself, so the smaller / simpler your install experience, the less WiX you need. You can find example WiX files under [examples](https://github.com/puppetlabs/vanagon/examples/resources/windows/wix).  These files should provide a good start to create an MSI using vanagon.

Vanagon searches for WiX files under the resources/windows/wix directory of the project. Any WiX files and vanagon default WiX overrides go to that directory.

### Components
As a special note, take care to understand the difference in language between vanagon and MSIs: vanagon uses "component" to describe the "component" defined in a config, a facility or sub-group within a package. Whereas MSIs define a component as an individual installable component (a file or service)

The process vanagon uses to actually build the MSI follows the normal path used for Unix based projects; vanagon builds each component on a build system, moves everything to a staging directory, then packages everything up.  In order to construct components on a windows system follow the usual vanagon pattern set out in the [styleguide](https://github.com/puppetlabs/vanagon/blob/master/docs/STYLEGUIDE.md).

Component files and project files likely require some differentiation based on installation between Unix and Windows. Common practice to deal with the differences is to use the is_"platform"? commands to create different branches of configuration. A list of the available is_"platform"? Functions can be found under [platform.rb](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/platform.rb).

Once the components successfully build on the build system, vanagon will tar up the combined source and then unpack it under /var/tmp/#{workdir}/SourceDir. For reference, SourceDir contains exactly what the install will look like from a component standpoint.  This is a good place to check for directory and file structure.  After unpacking the components to SourceDir vanagon uses the WiX compiler to create an MSI.

### WiX Compiler
Vanagon uses three parts of the WiX toolset to generate, compile and link WiX files to create a final MSI. Information about the compilation and link steps aren’t specifically pertinent to the use of vanagon. Vanagon projects don’t require changes to those steps to work. Refer to the Vanagon specifications documentation for more info and WiX docs on the linker and compiler.

Vanagon projects may require some knowledge of the generation step. WiX provides the “heat” tool to generate elements corresponding to every file and directory inside an input directory. WiX refers to this process as a "harvest". Vanagon uses the heat tool to generate an “AppComponentGroup” element containing elements for every file and folder under the installation directory. Note WiX provides the heat tool to harvest files in to a simple output, heat does not provide the user the abiltiy to special case any file attributes. If a project must create specific files/directories with specific attributes (such as a permanent file or folder) those files/directories need to be filtered out from the execution of heat.

Filtering files from heat consists of using an xml filter as input to heat.exe. Heat automatically filters out anything that file matches to. Currently, vanagon contains a [filter](https://github.com/puppetlabs/vanagon/blob/master/resources/windows/wix/filter.xslt.erb) for service files. To filter out other files, move a copy of that filter to the project resources/windows/wix dir, then extend the filter to add the other files (instructions about overriding files like this is available later in this document).

Due to the appdata directory tendency to be special case (specifically the fact that files and directories there are usually permanent) heat will not run there. The heat operation only provides a use case for simple file definitions. Therefore appdata directories and files will require a static WiX definition. Because the heat operation does not run on the appdata directory, no extra work is required of the filter for the appdata directory or it's files.

### WiX Files
MSI creation is too open ended to fully cover in this document, instead vanagon has a set of simple WiX examples to get started. These examples create a simple MSI installer without much input. The general setup that vanagon uses in the example project breaks down WiX files in the following hierarchy:

* At the top level, project.wxs includes the very top “product” WiX element, “package”, “upgrade” elements etc. as well as a “feature” element containing the componentgroupref “MainComponentGroup”
* Under the top level, vanagon uses a componentgroup.wxs file to force the inclusion of all other WiX files / elements by use of the “MainComponentGroup” element
* Under the componentgroup file, all other files contain at their top level a componentgroup element corresponding to a componentgroupref element inside the componentgroup file.

This is by no means a requirement for a vanagon project’s WiX structure to work for windows. Vanagon uses this structure as the most logical way to deal with the requirements created by vanagon’s WiX functionality. The only strict requirements in vanagon are:

* the componentgroupref element “AppComponentGroup” is included in the project
* Any file/directory that requires special attributes in it’s corresponding file component element needs to be filtered out of heat. (this does not apply to the appdata dir)
* Service components contain the attribute: Directory="<%= get_service("component_name").bindir_id %>"
* There is a corresponding install_service in the component’s vanagon config for any service file and there is a File element containing the service file in question inside a static WiX file.
* All files and directories under the appdata directory are explicitly defined using WiX in a static file. (Again this entire directory is left out of the execution of heat)

Other than those requirements, the WiX example is basically suggestion. Again WiX is very open ended and powerful, so it’s entirely viable to create an entirely different WiX setup.

For more information on WiX, refer to the [documentation](http://wixtoolset.org/documentation/manual/v3/) and [tutorial](https://www.firegiant.com/wix/tutorial/)

### Overriding WiX files provided by vanagon
Currently vanagon carries two files WiX will use while compiling a project. Vanagon provides the [filter](https://github.com/puppetlabs/vanagon/blob/master/resources/windows/wix/filter.xslt.erb) and [directorylist](https://github.com/puppetlabs/vanagon/blob/master/resources/windows/wix/directorylist.wxs.erb) as defaults. If the user needs to override either of these files the process is simple: copy the files to the project under the resources/windows/wix directory and retain the names. Then modify the files to fit project requirements. Vanagon will automatically prefer the WiX files in the project directory over those provided as "defaults". Note to take special care when changing the files. These two files are provided by vanagon due to their sensitive nature in respect the way vanagon works. Extending the files shouldn't cause problems; but fundamentally changing their existing functionality should be done with extreme care.

Current use cases for overriding the two default files are:

* update the filter to add files in the installation directory that need special attention. Note that if a project requires this the user also must create a static WiX file actually containing that special cased file definition.

* update the directorylist to create a different default installation location. Currently vanagon uses directorylist to define the default installation location as the file creates the INSTALLDIR property, which vanagon uses to point the heat output to a location. Changing the underlying structure before the INSTALLDIR property will change the default location of installation.