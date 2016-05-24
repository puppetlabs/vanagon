# Vanagon
- Note that this is an incomplete doc, documentation on all aspects of vanagon to come

## Vanagon for the Windows platform

### Overview
Vanagon was adapted for the windows platform using [WiX](http://wixtoolset.org/). At a very high level each component of the project gets built on a build system, then gets moved to a staging directory where we use the WiX toolset to build an MSI. This workflow is consistent with the rest of vanagon, however the WiX toolset creates some caveats, specifically:

* Vanagon does not contain functionality to handle registry searching
* Vanagon does not contain functionality to handle the MSI UI
* If the project requires MSI custom actions (such as those to search the registry, set properties used in the MSI etc.) Vanagon has no functionality to handle those
* For directories and files that require special attention (Such as a requirement for an app data directory to persist after uninstall) vanagon cannot handle them
* Vanagon cannot handle the service files required by WiX for an MSI
* Vanagon cannot handle the localization engine that MSIs use
* For localisation purposes, key Windows directories (e.g. Program files) must be specified using the install time dependancy localisation structure for windows

We deal with these special cases by allowing the user to provide their own WiX files inside the vanagon project. This way the user can use the WiX toolset to solve problems like registry searching and service files.

It’s possible many of these edge cases can be remedied in future releases of vanagon, such as the special casing of directories and files. But the benefit of “consistency” may not be enough to drive change for other cases, specifically because for things like custom actions the changes to vanagon would be so drastic and edge cased for windows, vanagon would start to look inconsistent with itself.

### Vanagon classes, functions, and WiX
We made no major changes to the overall class structure in vanagon, most of the work has been done in the class functions to incorporate WiX. Following along the Vanagon::Driver class function [run](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/driver.rb#L89L116) :

1. [Install_build_dependancies](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/driver.rb#L98) remains unchanged. The underlying changes required to get dependencies for windows lies in the actual project, not vanagon itself.
2. [Fetch_sources](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/driver.rb#L99) also remains unchanged, though take note that this is NOT where we fetch any of the WiX source files. However this is where we will grab any .bat files to be put on the user’s PATH on install.
3. [Make_makefile](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/driver.rb#L100) is where some of the WiX magic begins to happen. Specifically the WiX compiler invocation exists under the generate_package function of Vanagon::Platform::Windows
4. [Make_bill_of_materials](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/driver.rb#L101) remains unchanged
6. [Generate_pacakging_artifacts](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/driver.rb#L102) is where we are actually adding / generating WiX files for the compiler to use. If you follow the objects down eventually you’ll find the [generate_msi_packaging_artifacts](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/platform/windows.rb#L34L48) function inside Vanagon::Platform::Windows, where you’ll notice we do a mix of taking default files in vanagon and files from the project source and putting them in the workdir.
7. - 10. The [remainder](https://github.com/puppetlabs/vanagon/blob/master/lib/vanagon/driver.rb#L103L106) of the driver functionality remains unchanged

You’ll notice that in vanagon, most of the functionality changes we made to ruby files was in Vanagon::Platform::Windows. However the WiX default files under resources/windows/wix also contain a large part of the new functionality.

### The Vanagon::Platform::Windows class
This is the meat and potatoes of the windows vanagon work, the main functionality for building an MSI exists in two places:

* generate_msi_package , where we actually invoke the WiX compiler. This function returns a string that vanagon pushes into the Makefile. That string contains the proper incantation in WiX to generate the required WiX source files and then compile and link everything together into an MSI.
* generate_msi_packaging_artifacts, where we pull WiX source files from the project and generate defaults from vanagon, then stage all the WiX files.

generate_msi_packaging_artifacts is how we avoid loading vanagon with large windows edge cases for the windows caveats from earlier. The idea: instead of forcing vanagon to automagically generate the appropriate WiX files, we generate everything we can; for the rest we allow the user to specify their own static WiX files that vanagon will stage and compile with its own defaults.

For the actual staging of the files, vanagon uses the same process for components in windows as in other platforms. Components install onto the build system, then vanagon moves them to a staging directory. From this staging directory Vanagon executes the WiX compiler stages to generate files and compile the MSI together.

### Windows Paths
Before diving into the specifics of the WiX compiler it’s important to understand the windows pathing paradigm that WiX uses for the installation location of MSIs.

Inside Vanagon::Platform::Windows.generate_msi_package, vanagon uses specific names for the staging directory. Specifically the SourceDir directory is important, because SourceDir is an MSI naming convention. The name refers to the “root” of the source files to be included in install. The idea behind the “root” is it provides the user creating an MSI a link to where the software installs to. On install, the MSI will recreate the entire structure (starting from SourceDir) in the install location, which will default to the largest drive, i.e. something like C:\. A good explanation for this is [here](http://stackoverflow.com/questions/1641094/in-wix-files-what-does-name-sourcedir-refer-to)

Other than SourceDir the other related naming convention is ProgramFilesFolder / ProgramFiles64Folder. These two names are [MSI defaults](https://msdn.microsoft.com/en-us/library/windows/desktop/aa370905(v=vs.85).aspx) that allow us to utilize the localization engine for MSIs. On install these folders will resolve to the actual program files standard for windows, i.e. Program Files or Program Files (x86).

### The WiX Compiler
Vanagon uses three parts of the WiX compiler to construct an MSI from both the available WiX files and the components inside. As mentioned before, Vanagon stages all components in a staging directory. From this staging directory Vanagon executes the first WiX function: heat.exe. Heat will iterate over the entire staging directory and generate the necessary WiX file containing each file and directory under the staging directory.

After heat Vanagon executes the compiler (candle.exe) then the linker (light.exe) on all WiX files staged to create the MSI. These two stages of WiX will happen on all files. Both those created dynamically by heat.exe / vanagon, and those static ones created by the user.

### Heat.exe
The heat process generates appropriate WiX elements corresponding to each file and directory under the stagedir, WiX refers to the heat process as a "harvest". Vanagon uses heat’s output alongside the other static WiX files to include all files under the stagedir in the final MSI.

Heat uses the SourceDir naming convention via input parameters to the command line. Vanagon projects add things like the appdata directories seperately from the harvest. Vanagon uses this workflow because harvests form heat only export simplified file and directory elements. It’s likely the files/directories that go in appdata need specific attributes (such as permanent files and directories). In order to work around this vanagon does not run heat.exe from SourceDir. In order to collect only those files NOT under appdata, vanagon runs heat.exe from the path:

SourceDir/ProgramFilesFolder/Company ID/Product Name/

which is the standard installation path for a product on windows. However, heat expects the directory it’s running from to be SourceDir. In order to override that default expectation we do a few things:

1. “-var” , Vanagon passes a preprocessor variable to heat with -var, which will replace the actual sourcedir string in any paths with the preprocessor variable.
2. “-d” , we pass the actual value of the preprocessor variable (which will be the remainder of the path under where heat is executing, i.e. SourceDir/ProgramFilesFolder/Company ID/Product) to candle.exe so that the variable is actually evaluated at compile time.

As mentioned before heat does not run on any common application data or directories, these require a static WiX file. With this static WiX file and heat vanagon will pull in all files and directories staged in the staging directory. There is a single exception to all of this, as service files need special handling in WiX.

### Service Files
Service executables need special attention in WiX. Service files themselves cannot be listed as part of the output from heat.exe. The files themselves need special attention. Allowing them to exists as elements inside the heat output will collide with the work we need to do.

To solve this we need to use an xml filter on the execution of heat.exe. While this is not the perfect solution, since WiX is based on xml, using a filter will solve our problems. The filter for service files exists in vanagon, since the user should not change it. The filter searches for elements in the heat output matching any one of the service files specified using component.install_service in component files.

To the end user, this means services are not automatically added to vanagon by only using install_service. The files themselves will get moved to the staging directory, but they will not exist anywhere in WiX. This workflow is by design. WiX service elements are very complex, and due to this will likely never be generated by vanagon itself. Users will be required to provide their own static WiX files for any services.

The one thing that vanagon does provide for WiX service files is access to the directory with the actual service binaries. WiX requires service elements exist as children under a component element with a “directory” attribute. This reference should be the directory that the binary actually exists in. Vanagon provides this directory through the bindir_id function of components. The correct invocation for the user will include grabbing the specific component they are looking to add a service to. For example:

Directory="<%= get_service("marionette-collective").bindir_id %>"

More information about the actual specific WiX services can be found under the ServiceControl/Install/Config children of the wix element [component](http://wixtoolset.org/documentation/manual/v3/xsd/wix/component.html)

### Directorylist.wxs
In order to facilitate the bindir_id method in components, vanagon uses a WiX file and platform function to create a list of the service directories. The file (directorylist.wxs in vanagon) operates using non-named directory elements. Vanagon uses the fact that If you create a directory element with no name attribute, the element won’t exist as a new directory, but a reference to its parent element’s directory.

The directorylist file itself is simple, it creates the necessary root directories in WiX, then inside the last directory it calls out to Vanagon::Platform::Windows.generate_service_bin_dirs. This function does a two things for each service file:

1. Generates the necessary directories underneath where the file is, these directory elements will have names and resolve to a path
2. Generates one last element underneath the top direcotory with no name and bindir_id as the id element. This provides the necessary connection between bindir_id and the actual directory containing binaries. As discussed before because this element has no name it will resolve to it’s parent directory element, the top level directory.

In cases where there is more than one bindir_id corresponding to the same place there is no problem, there will just be two nameless directory elements under that directory. This is allowed in WiX because they have no names.

### INSTALLDIR
Inside the directorylist file the last root directory defined has the unique id [INSTALLDIR](https://github.com/puppetlabs/vanagon/blob/master/resources/windows/wix/directorylist.wxs.erb#L7). Vanagon uses this name on purpose. Used correctly, INSTALLDIR provides the user the means to change the location of the final install of the MSI. Using WiX properties and the INSTALLDIR variable the user can override all root directories underneath INSTALLDIR with what the end user wants.

Note that this is in no way the correct way for the vanagon user to override directorylist root install defaults. If the user wishes the default installation location to be something other than DRIVE:/ProgramFilesFolder/CompanyName/ProductName they should override the entire directorylist file with a file of the same name in their own project. Vanagon will default to using the one in their project.

INSTALLDIR itself is not a WiX property or requirement, the name was a convention that vanagon uses.

### Candle.exe
Once we unpacked everything into the staging directory, run heat.exe on its contents and executed the vanagon erb functionality on all WiX files, we need to actually compile the WiX files. Candle.exe is akin to the actual compile step of compilers.

The invocation of candle is very straightforward, with one caveat: as discussed earlier, we need to pass the preprocessor variable “AppSourcePath” for heat to use.

More information on the Candle compiler:

* [docs](http://wixtoolset.org/documentation/manual/v3/)
* [tools](http://wixtoolset.org/documentation/manual/v3/overview/alltools.html)

### Light.exe
Light.exe is akin to the linking step in compilers. In the invocation of light we don’t use anything out of the ordinary, we simply pass it what the location the files exist in, and where the output file should go. At this point the WiX compiler passes any localisation strings provided in the project to the MSI. The output of Light.exe is an actual MSI, so after this step vanagon has completed compilation.
