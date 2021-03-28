# Gateau CMake Modules

*Gateau* consists in a set of CMake modules that make working with CMake both
easier and safer.

It has been designed as a pragmatic tool to quickly create a working CMake
configuration for C++ projects. As such, it is quite opinionated and equipped to
handle the situations I commonly encounter. However, it may not be able to cope
with random project layouts and unusual or complex needs.
My primary use case for Gateau is avoiding repeating myself again and again by
copy pasting the same code from project to project, and keeping clear of all the
tedious boilerplate that distracts me from the real task at hand.

This tool is currently being used to build C++ software, mostly on GNU/Linux,
sometimes on MS Windows, using the GCC, Clang and MinGW compilers. Help will be
needed to improve compatibility with other systems and compiler combinations.

## Features

Gateau aims to simplify the definition of the CMake configuration for your
project. To paraphrase a famous book title, It does so by automating the boring
stuff, and choosing sane defaults so you don't need to.

It contains a few functions, macros and configuration variables that make it
very simple to create an installable project with external dependencies, a few
targets, unit tests and generated documentation.

In particular it is capable of:

- Setting up useful options to make C++ development convenient:
  - Sane compiler options,
  - Sanitizers integration,
  - LTO, CCache use...
- Looking for dependencies, downloading and compiling them for you if missing,
- Declaring new targets that will be configured in a sensible way for you to
  make it both installable and importable by other projects. An export header
  and version header get generated for every target.
- Making targets trivially installable, with automatic installation of binaries,
  headers as well as generation of CMake config, version and target modules so
  that your project can be found and used by other projects.
- Declaring tests in a simple way,
- Automatically generating Doxygen documentation,
- ...

Again, it is a simple tool, not a full-fledged package manager. It does not
particularly excel at dependency handling and will not be able to cope with
complex dependency chains.

## Motivational example

The following file listings illustrate the main features of Gateau. For a more
complete overview, the examples directory showcases both the complete installable
project presented below as well as a second project using the first one as an
external dependency.

### Main CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.15)

# Project definition
project(eclair
    VERSION 0.1
    DESCRIPTION "A yummy project"
    HOMEPAGE_URL "https://www.yummy-eclair.pro"
    LANGUAGES CXX
)

# Include Gateau by fetching it. One may also use it as a submodule
include(FetchContent)
FetchContent_Declare(gateau GIT_REPOSITORY https://github.com/palacaze/gateau.git)
FetchContent_MakeAvailable(gateau)
include(${gateau_SOURCE_DIR}/Gateau.cmake)

# Configure gateau for this project
gateau_configure(
    EXTERNAL_ROOT "${PROJECT_BINARY_DIR}/3rdparty"
    OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin"
    GENERATED_HEADER_CASE HYPHEN
    GENERATED_HEADER_EXT hpp
)

# Looking for fmtlib
gateau_find_package(fmt GIT https://github.com/fmtlib/fmt)

# The main sources
add_subdirectory(src)

# Tests
if (ECLAIR_BUILD_TESTS)
    add_subdirectory(test)
endif()

# Documentation
if (ECLAIR_BUILD_DOC)
    gateau_build_documentation(
        EXCLUDED_SYMBOLS
            detail  # exclude "detail" namespace
            _*      # and symbols starting with a "_"
    )
endif()

# Other files we would like to see in the IDE
file(GLOB_RECURSE _doc_files "doc/*.md")
gateau_other_files(Doc
    README.md
    ${_doc_files}
)

# Installation
gateau_install_project()
```

### src/eclair/CMakeLists.txt

```cmake
# Create the "lib" library
gateau_add_library(lib
    SOURCES
        eclair.cpp
    HEADERS
        eclair.hpp
    LINK_LIBRARIES
        PUBLIC
            fmt
)
```

### src/bakery/CMakeLists.txt

```cmake
# Create an executable that uses the "lib" library
gateau_add_executable(bakery
    SOURCES bakery.cpp
    LINK_LIBRARIES eclair::lib
)
```

### test/CMakeLists.txt

```cmake
# I use Doctest for my unit tests
gateau_setup_testing(tests DOCTEST)

gateau_add_test(test-lib
    SOURCES
        test-lib.cpp
        test-main.cpp
    LINK_LIBRARIES
        eclair::lib
)
```

## Status

Works for me. I use *Gateau* for several projects and it works surprisingly well for
what I want. It has not been tested at all on Windows yet, but it will someday.

My TODO list includes a lot of potentially useful stuff, but I do not require these
features right now so I make no promise.

- Install headers only libs from an archive file or path,
- Allow a gateau_fetch_package() that uses FetchContent instead of ExternalProject,
- Support Qt translations,
- Support Gitlab, Gihub automation,
- Automated project deployment and packaging, for instance with CPack,
- Conan integration,
- Add an option for configurable compiler flags.
- Allow Package modules versioning,
- ...

## Requirements

### CMake

Only CMake is needed. Version 3.15 or later is mandatory, as Gateau modules
rely on recent CMake constructs to achieve their goals.

### Project organization

The project layout on the file system is not imposed but it is recommended to
organize public headers in the same way you want them installed. That way it will
be possible to automate installation.

A possible layout is the following:

```
Project
├── CMakeLists.txt
├── data/
│  └── Misc.svg
├── doc/
├── example/
│  ├── CMakeLists.txt
│  ├── Example1.cpp
│  └── Example2.cpp
├── README.md
├── src/
│  └── Project/
│     └── Target/
│        ├── CMakeLists.txt
│        ├── File.h
│        ├── File.cpp
│        └── PublicHeader1.h
│        └── PublicHeader2.h
└── test/
   ├── CMakeLists.txt
   ├── Test1.cpp
   └── Test2.cpp
```

This makes it possible to `#include <Project/Target/PublicHeader1.h>` from any
other public header. Having `test` and `example` directories (notice the singular)
allow defining idiomatic `tests` and `examples` CMake targets.


Another popular layout is to put the public headers in the `include` directory:

```
Project
├── CMakeLists.txt
├── include/
│  └── Project/
│     └── Target/
│        ├── CMakeLists.txt
│        └── PublicHeader1.h
│        └── PublicHeader2.h
├── README.md
├── src/
   └── Target/
      ├── CMakeLists.txt
      ├── File.h
      ├── File.cpp
```

*Gateau* can be customized to look for public headers from other base directories,
chances are that you current project layout can be handled with no change.

## User Manual

The Gateau.cmake module is the main entry point of Gateau's CMake modules
distribution. It should be included right after the call project() command, near
the top of a project's top level CMakeLists.txt.

All the other modules are included from this one, so no other inclusion is
necessary.

CMake version 3.15 or later is required.

### Using Gateau in your project

One can include *Gateau* as a git submodule, integrate it in its own project or simply
use FetchContent to incorporate it at configuration time.

The following snippet near the top of the root CMakeLists.txt of a project should suffice:

```cmake
# Fetch Gateau
include(FetchContent)
FetchContent_Declare(gateau GIT_REPOSITORY https://github.com/palacaze/gateau.git)
FetchContent_MakeAvailable(gateau)
include(${gateau_SOURCE_DIR}/Gateau.cmake)
```

### Configuration and user visible options

After inclusion of Gateau's main module, a number of cache variables get defined.
They can be categorized into 4 different groups:

- Internal variables used by *Gateau* itself,
- Variables that describe the system,
- Hidden variables used to setup low-level aspects of a *Gateau*-based project,
- User-visible variables that can be used to tweak the configuration of a project.

Each variable is prefixed with an identifier created from the project name. The
identifier is obtained by separating the words of the project name and producing
an all-caps C identifier equivalent string of it. For instance:

| Project Name | Equivalent Prefix |
|--------------|-------------------|
| myproj       | MYPROJ            |
| my-proj      | MY_PROJ           |
| Myproj       | MYPROJ            |
| MyProj       | MY_PROJ           |
| my_proj      | MY_PROJ           |

This prefix identifier is stored in the `${PROJECT_NAME}_IDENT` cache variable.
The reason for prefixing variables is to allow Gateau-based sub-projects.

Here is a breakdown of the variables generated by *Gateau*, by type.

#### Informative variables

Those are conceptually read-only.

| Variable              | Description                                    | Value     |
|-----------------------|------------------------------------------------|-----------|
| ${PROJECT_NAME}_IDENT | The identifier string used to prefix variables | ${ID}     |
| ${ID}_ARCH            | The architecture pointer size                  | 32 or 64  |
| ${ID}_X32             | Is this a 32 bits build                        | ON or OFF |
| ${ID}_X64             | Is this a 64 bits build                        | ON or OFF |

#### Low-level configuration variables

Those are meant for the project developers.

| Variable                    | Description                                       | Default                        |
|-----------------------------|---------------------------------------------------|--------------------------------|
| ${ID}_RELATIVE_HEADERS_DIRS | Dirs where headers are expected to be found       | src;include;Src;Source;Include |
| ${ID}_GENERATED_HEADER_CASE | How to name generated headers (CAMEL/SNAKE/HYPEN) | SNAKE                          |
| ${ID}_GENERATED_HEADER_EXT  | Extension of generated headers                    | "hpp"                          |
| ${ID}_NAMESPACE             | The namespace used for alias targets and exports  | "${PROJECT_NAME}"              |
| ${ID}_C_STANDARD            | The C standard to use                             | c_std_99                       |
| ${ID}_CXX_STANDARD          | The C++ standard to use                           | cxx_std_17                     |

`${ID}_RELATIVE_HEADERS_DIRS` can be used to teach *Gateau* about the project layout,
and will be used to install the project's development headers correctly.

`${ID}_GENERATED_HEADER_CASE` and `${ID}_GENERATED_HEADER_EXT` and describes
how one wishes the generated headers to be named. Right now, two header
files may be generated for a given target: a version header and an export
header.

| Case   | Result           |
|--------|------------------|
| CAMEL  | TargetVersion.h  |
| SNAKE  | target_version.h |
| HYPHEN | target-version.h |

#### Options and cache variables

The following variables can be set by the user to tweak how the project will be
configured and built. They can grouped thematically.

##### Options that control what gets built

The `${ID}_BUILD_XXXX` options can be used by the project developer to selectively
deactivate parts of the project to be built.

| Option                 | Description         | Default |
|------------------------|---------------------|---------|
| ${ID}_BUILD_EXAMPLES   | Build code examples | ON      |
| ${ID}_BUILD_TESTS      | Build tests         | ON      |
| ${ID}_BUILD_DOC        | Build documentation | ON      |
| ${ID}_BUILD_BENCHMARKS | Build benchmarks    | OFF     |

##### Options that affect the compilation

A number of options can be used to change the compiler flags.

| Option                         | Description                                                   | Default    |
|--------------------------------|---------------------------------------------------------------|------------|
| ${ID}_ENABLE_AUTOSELECT_LINKER | Select the best available linker                              | ON         |
| ${ID}_ENABLE_COMMON_WARNINGS   | Enable common compiler flags                                  | ON         |
| ${ID}_ENABLE_LIBCXX            | Use libc++ instead of gcc standard library                    | OFF        |
| ${ID}_ENABLE_LTO               | Enable link time optimization (release only)                  | OFF        |
| ${ID}_ENABLE_MANY_WARNINGS     | Enable more compiler warnings                                 | OFF        |
| ${ID}_ENABLE_PROFILING         | Add compile flags to help with profiling                      | OFF        |
| ${ID}_ENABLE_WERROR            | Enable werror for a few important compiler flags              | ON         |
| ${ID}_KEEP_TEMPS               | Keep temporary compiler-generated files for debugging purpose | OFF        |
| ${ID}_SANITIZE_ADDRESS         | Compile with address sanitizer support                        | OFF        |
| ${ID}_SANITIZE_THREADS         | Compile with thread sanitizer support                         | OFF        |
| ${ID}_SANITIZE_UNDEFINED       | Compile with undefined sanitizer support                      | OFF        |
| ${ID}_SPLIT_DEBUG_INFO         | Split debug info (may not compatible with sanitizers)         | ON         |
| ${ID}_USE_CCACHE               | Use Ccache to speed-up compilation                            | OFF        |

##### Options that control where build artifacts get stored

`BD = PROJECT_BINARY_DIR`

| Option                   | Description                               | Default   |
|--------------------------|-------------------------------------------|-----------|
| ${ID}_OUTPUT_DIRECTORY   | Where to place compiled targets           | ""        |
| ${ID}_DOCUMENTATION_ROOT | Documentation installation root directory | ${BD}/doc |

##### Options that control how external dependencies are build

Gateau has limited ability to install missing external dependencies. This feature
can be disabled with the `${ID}_NO_INSTALL_DEPS` option. At the other side of the
spectrum, `${ID}_UPDATE_DEPS` can be used to instruct Gateau to update external
dependencies. This is useful for projects that rely on multiple related third
party components highly coupled but managed in distinct repositories.

The other options are meant to tweak external dependencies handling.

| Option                        | Description                                                   | Default                |
|-------------------------------|---------------------------------------------------------------|------------------------|
| ${ID}_NO_BUILD_DEPS           | Prevent Gateau from building missing external dependencies    | OFF                    |
| ${ID}_UPDATE_DEPS             | Update the external packages when the project is reconfigured | OFF                    |
| ${ID}_EXTERNAL_ROOT           | Root directory where external packages get handled            | ${BD}/external         |
| ${ID}_EXTERNAL_BUILD_TYPE     | Build type used to build external packages                    | Release                |
| ${ID}_EXTERNAL_INSTALL_PREFIX | Prefix where to install built external packages               | EXTERNAL_ROOT/prefix   |
| ${ID}_DOWNLOAD_CACHE          | Directory that acts as a download cache for external packages | EXTERNAL_ROOT/download |

### Project creation

Apart from including the main *Gateau* module, some of the configuration variables,
the one targeting the project itself, can be passed using an optional call to
*gateau_configure*.

```
gateau_configure(
    [NO_BUILD_DEPS] [UPDATE_DEPS]
    [C_STANDARD <c_std>] [CXX_STANDARD <cxx_std>]
    [GENERATED_HEADER_CASE <CAMEL|SNAKE|HYPHEN>]
    [GENERATED_HEADER_EXT <ext>]
    [OUTPUT_DIRECTORY <out_dir>]
    [DOWNLOAD_CACHE <down_dir>]
    [NAMESPACE <namespace>]
    [EXTERNAL_BUILD_TYPE <build_type>]
    [EXTERNAL_ROOT <ext_root_dir>]
    [EXTERNAL_INSTALL_PREFIX <ext_prefix>]
    [RELATIVE_HEADERS_DIRS [items...]])

```

The options are the same as described earlier, and allow the project developer
to tweak Gateau for the needs of the project.

### Finding dependencies

*Gateau* offers a wrapper over the find_packages facilities to improve and
extend the function to include automated compilation of external dependencies
as well as integrate those dependencies in the CMake find modules that will
be generated for the project.

To do so, simply replace calls to `find_package` with calls to `gateau_find_package`.

This macro supplements the `find_package` function with additional features that
allow overriding package finding instructions, as well as instruct CMake how to
download, and install the dependency itself if it was not found.

To do so, Gateau relies on the creation of special CMake modules, named after the
package to be found, which define variables and a couple of macros to instruct
Gateau on how the package should be found and installed. Installation itself is
deferred to the CMake ExternalProject module.

Gateau comes with a few custom package instruction modules for dependencies I use
or have used in the past. Any project can add additional modules in its own tree
by declaring the directory that contains them to *Gateau*.

```
# Add a directory to the list of directories to search when looking for a
# package module file with installation instructions for external dependencies.
gateau_add_package_module_dir(<dir>)
```

Creating such modules is not mandatory to benefit from the capabilities offered
by `gateau_find_package`. One can also supply custom directives directly to the
macro. For this reason, `gateau_find_package` offers a number of parameters,
most of them mirror those from ExternalProject_add, which will mostly be passed
as-is to the function.

```
gateau_find_package(<name>
    [IN_SOURCE]
    [NO_EXTRACT] [NO_PATCH] [NO_UPDATE]
    [NO_CONFIGURE] [NO_BUILD] [NO_INSTALL]
    [OPTIONAL]
    [BUILD_ONLY_DEP]
    [UPDATE_DEP]
    [GIT <git_url>]
    [TAG <git_tag>]
    [URL <file_url>]
    [MD5 <file_md5>]
    [SOURCE_SUBDIR <subdir>]
    [SINGLE_HEADER <header_url>]
    [CMAKE_CACHE_ARGS args...]
    [CMAKE_ARGS args...]
    [PATCH_COMMAND commands...]
    [UPDATE_COMMAND commands...]
    [CONFIGURE_COMMAND commands...]
    [BUILD_COMMAND commands...]
    [INSTALL_COMMAND commands...])
```

Contrary to find_package, gateau_find_package defaults to `REQUIRED`. For optional
dependencies, the `OPTIONAL` keyword must be used.

That way, by merely adding a GIT or URL directive to `gateau_find_package`, one can
transform a normal `find_package` directive into one that can fetch compile and install
the dependency for you (assuming a CMake installable dependency).

Here is one such example:

```cmake
gateau_find_package(spdlog https://github.com/gabime/spdlog)
gateau_add_executable(foo
    SOURCES foo.cpp
    LINK_LIBRARIES spdlog::spdlog)

```

#### Build-only dependencies

Some dependencies may be build-only deps, for instance headers-only libraries used
in private parts or code generation tools. The installed package does not depend on
it and as such does not constitute a runtime dependency. Those can be marked using
the `BUILD_ONLY_DEP` option, and will not be added to the package config module
installed with the package.

#### Special case for single header libraries

`gateau_find_package` possesses an option dedicated to single header libraries.
It allows installing such a library by supplying an URL to the header file.

The `${name}::${name}` import target gets generated automatically and can be linked to.

```cmake
gateau_find_package(date
    SINGLE_HEADER "https://github.com/HowardHinnant/date/raw/master/include/date/date.h")
gateau_add_executable(foo
    SOURCES foo.cpp
    LINK_LIBRARIES date::date)
```

#### Creating package modules for external dependencies

A package module file named after the dependency to be installed and placed in an appropriate
directory can be created to instruct Gateau how to find and install a particular package.
The complete file will be sourced by Gateau.

The variables accepted by gateau_find_package can be defined in this module, but must
be prefixed with the package name. For instance, the module for a package "Dep" may
contain the variable Dep_URL.

Moreover, two macros may optionally be defined, also prefixed with the package name:

- ${dep}_find(name optional_find_options...)
- ${dep}_install(name)

The first macro gets called when the dependency is searched. A default implementation would
dispatch all the arguments to find_package(). This is where one would handle custom search
procedure and define import targets if the default package distribution does not provide any,
for instance for old style cmake packages and non-cmake built packages.

The second is responsible for installing the dependency, and gets called if the depenency
was not found. Most of the time, one wants to use `gateau_install_dependency()` for that.
This is a wrapper over ExternalProject_add that knows how to use some variables prefixed with
the package name to setup the installation procedure.

For illustration purpose, here is a complete annoted module example of package module for
a dependency that is not CMake compatible:

```cmake
# This is asio.cmake, a package module that provides custom search and installation
# procedure for the standalone asio library.

# First a couple of variables that instruct gateau_install_dependency() how to fetch
# the asio source code from its git repository.
set(asio_GIT "https://github.com/chriskohlhoff/asio.git")
set(asio_TAG "asio-1-18-0")

# The _find macro gets called when the package is searched.
macro(asio_find name)
    # Standard package finding procedure
    include(FindPackageHandleStandardArgs)

    find_path(asio_INCLUDE_DIR
        NAMES io_service.hpp
        PATH_SUFFIXES asio
    )

    find_package_handle_standard_args(
        asio DEFAULT_MSG asio_INCLUDE_DIR)

    mark_as_advanced(asio_INCLUDE_DIR)

    # We also create an import target for nicer use
    if(asio_FOUND AND NOT TARGET asio::asio)
        add_library(asio::asio INTERFACE IMPORTED)
        set_target_properties(asio::asio PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${asio_INCLUDE_DIR}"
        )
        target_compile_definitions(asio::asio INTERFACE
            BOOST_ASIO_NO_DEPRECATED
            BOOST_ASIO_STANDALONE
            BOOST_ASIO_HEADER_ONLY
        )
    endif()
endmacro()

# The _install macro is called to install the package is not found.
macro(asio_install name)
    # Call to gateau_install_dependency, which installs the dep
    # For this header only package, we specifically instruct cmake to skip unwanted steps
    gateau_install_dependency(${name}
        NO_PATCH
        NO_CONFIGURE
        NO_BUILD
        INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory "<INSTALL_DIR>/include/asio"
                COMMAND ${CMAKE_COMMAND} -E copy_directory "<SOURCE_DIR>/asio/include/asio" "<INSTALL_DIR>/include/asio"
                COMMAND ${CMAKE_COMMAND} -E copy "<SOURCE_DIR>/asio/include/asio.hpp" "<INSTALL_DIR>/include"
    )
endmacro()
```

Most of the time, for packages already supporting CMake, the package module will
only contain a few variables to setup the package URL or GIT repo and custom CMAKE_ARGS.
The packages directory contains a few modules ready for use that can serve as example.

`gateau_install_dependency()` has the following signature:

```
# Function that simplifies working with ExternalProject_Add.
# It sets an ExternalProject up using the supplied available information and
# creates an install and uninstall target for later use.
#
# The list of recognized arguments is enumerated below, and mostly matches the
# names and meaning of the one accepted by ExternalProject_add.
#
# The arguments used to configure the external project are retrieved from two
# sources: the arguments supplied to the function, as well as any variable in
# scope that has the form ${dep}_OPTION_NAME, where OPTION_NAME is a variable
# name from the parameters list below.
#
# Unrecognized arguments will be passed as-is to ExternalProject_Add.
gateau_install_dependency(<name>
    [IN_SOURCE]
    [NO_EXTRACT] [NO_CONFIGURE] [NO_PATCH]
    [NO_UPDATE] [NO_BUILD] [NO_INSTALL]
    [GIT <git_repo>]
    [TAG <git_tag>]
    [URL <file_url>]
    [MD5 <file_md5>]
    [SOURCE_SUBDIR <subdir>]
    [GIT_CONFIG config...]
    [CMAKE_CACHE_ARGS args...]
    [CMAKE_ARGS args...]
    [PATCH_COMMAND cmds...]
    [UPDATE_COMMAND cmds...]
    [CONFIGURE_COMMAND cmds...]
    [BUILD_COMMAND cmds...]
    [INSTALL_COMMAND cmds...])
```

Look up the ExternalProject_add documentation for more information on each option.

### Creating targets

One of the design goals of *Gateau* is to provide clean an consistent APIs.
To that hand, the number of actual functions to create and configure targets is
reduced to the bare minimum:

- `gateau_add_library()` to create a new library target
- `gateau_add_executable()` to create a new executable target
- `gateau_extend_target()` to modify a target

Most aspects of a target can be parametrized through calls to those three functions.
The first two calls declare new library and executable targets respectively, whereas
the last one extends an already existing target.

All the parameters accepted by `gateau_extend_target()` can also be passed to the other
two functions, and will be forwarded to it.

#### Defining a new library target

```
gateau_add_library(<name>
    [STATIC | SHARED | OBJECT | MODULE | INTERFACE]
    [NO_INSTALL] [NO_INSTALL_HEADERS]
    [NO_EXPORT]
    [NO_EXPORT_HEADER]
    [NO_VERSION_HEADER]
    [INSTALL_BINDIR <dir>]
    [INSTALL_LIBDIR <dir>]
    [INSTALL_INCLUDEDIR <dir>]
    [other options accepted by gateau_extend_target()]...
)
```

The following options are accepted:

- One of STATIC SHARED OBJECT MODULE INTERFACE (defaults to SHARED): library type
- NO_INSTALL: do not install this target
- NO_INSTALL_HEADER: do not install the dev headers
- NO_EXPORT: the target is not exported to the cmake package module installed
- NO_EXPORT_HEADER: do not generate an export header
- NO_VERSION_HEADER: do not generate a version header
- INSTALL_BINDIR: override the binaries installation directory path
- INSTALL_LIBDIR: override the libraries installation directory path
- INSTALL_INCLUDEDIR: override the headers installation directory path
- Other options.... parameters forwarded to `gateau_extend_target()`

Automated installation and generation of both an export and version header are some of
the benefits of creating library targets through a call to `gateau_add_library()`.

The target also gets an alias of the form ${Project}::${Target} and also makes
use of all the options defined at project scope.

Most of the time, a single call to gateau_add_library() will suffice to
define the whole target. See the documentation for `gateau_extend_target()` below
to learn how to configure the other function parameters.

Also of note, `gateau_add_library()` should work out of the box with interface libraries.

#### Defining a new executable target

```
gateau_add_executable(<name>
    [NO_INSTALL]
    [NO_EXPORT]
    [VERSION_HEADER]
    [INSTALL_BINDIR <dir>]
    [other options accepted by gateau_extend_target()]...
)
```

The following options are accepted:

- One of STATIC SHARED OBJECT MODULE INTERFACE (defaults to SHARED): library type
- NO_INSTALL: do not install this target
- NO_EXPORT: the target is not exported to the cmake package module installed
- VERSION_HEADER: do generate a version header
- INSTALL_BINDIR: override the binaries installation directory path
- Other options.... parameters forwarded to `gateau_extend_target()`

#### Configuring a target

Both `gateau_add_library()` and `gateau_add_executable()` forward unused arguments to
`gateau_extend_target()`. Several calls to this function can be performed to augment
a target.

```
gateau_extend_target(<target>
    [AUTOMOC]
    [AUTOUIC]
    [AUTORCC]
    [EXCLUDE_FROM_ALL]
    [NO_INSTALL_HEADERS]
    [CONDITION <condition>]
    [SOURCES             [PUBLIC|PRIVATE|INTERFACE] srcs...]
    [HEADERS             [PUBLIC|PRIVATE|INTERFACE] hdrs...]
    [COMPILE_DEFINITIONS [PUBLIC|PRIVATE|INTERFACE] defs...]
    [COMPILE_FEATURES    [PUBLIC|PRIVATE|INTERFACE] feats...]
    [COMPILE_OPTIONS     [PUBLIC|PRIVATE|INTERFACE] opts...]
    [INCLUDE_DIRECTORIES [PUBLIC|PRIVATE|INTERFACE] dirs...]
    [LINK_DIRECTORIES    [PUBLIC|PRIVATE|INTERFACE] dirs...]
    [LINK_OPTIONS        [PUBLIC|PRIVATE|INTERFACE] opts...]
    [LINK_LIBRARIES      [PUBLIC|PRIVATE|INTERFACE] libs...]
    [PROPERTIES          [PROP_NAME <prop_value>]...]
)
```

The function call wraps all the aspects of a target configuration, with options
that map to the various cmake functions that act on a target. Visibility can be
tweaked per option.
Here is a rundown:

- AUTOMOC, AUTOUIC and AUTORCC activate the corresponding properties for the target
- EXCLUDE_FROM_ALL excludes the target from the all target.
- NO_INSTALL_HEADERS skips headers installation for a target
- CONDITION a boolean that dictates if the call to `gateau_extend_target()` must be applied
- SOURCES calls `target_sources()`, declares non installable sources (and also private headers)
- HEADERS calls `target_sources()`, declares headers that must be installed with the binary target
- COMPILE_DEFINITIONS calls `target_compile_definitions()`
- COMPILE_FEATURES calls `target_compile_features()`
- COMPILE_OPTIONS calls `target_compile_options()`
- INCLUDE_DIRECTORIES `target_include_directories()`
- LINK_DIRECTORIES calls `target_link_directories()`
- LINK_OPTIONS calls `target_link_options()`
- LINK_LIBRARIES calls `target_link_libraries()`
- PROPERTIES calls `set_target_properties()` with the supplied property-value pairs

One can mix calls to Gateau functions with CMake normal calls, however this may be at the
expanse of automated headers accounting and installation.

### Installing a project

Most of the work is performed at target creation. The actual `install` target is created
through a simple call to `gateau_install_project()`, which will use the information
gathered from previous calls to `gateau_configure()`, `gateau_add_library()` and
`gateau_add_executable()`.
Consequently, it should be placed near the end of your root CMakelists.txt, after all
the targets to be installed have been defined.

### Generating documentation

*Gateau* can produce Doxygen generated documentation with minimal setup and a single call
to `gateau_build_documentation()`

```
# Generate documentation for this gateau project
gateau_build_documentation(
    [EXCLUDED_SYMBOLS symbol_regexes...]
    [PREDEFINED_MACROS macros]
    [INPUT_PATHS paths...]
    [EXCLUDED_PATHS paths])
```

- EXCLUDED_SYMBOLS: list of symbols to exclude from the documentation, defaults to "detail"
- PREDEFINED_MACROS: Preprocessor macros to define, with an optional value, when parsing files
- INPUT_PATHS: input paths whose files should be parsed in addition to "README.md" and files
  in the RELATIVE_HEADERS_DIRS list of source directories
- EXCLUDED_PATHS: paths that should be excluded from the parsing

Example use:

```
gateau_build_documentation(
    EXCLUDED_SYMBOLS
        MYPROJ_DETAIL*
        detail*
        _*
    PREDEFINED_MACROS
        MYPROJ_DECLARE_ENUM
    EXCLUDED_PATHS
        src/myproj/detail
        src/myproj/3rdparty
)
```

### Adding tests

*Gateau* tries to make it easy to add testcases to a project. It has build in support
for three commonly used test libraries: [Google Test](https://github.com/google/googletest),
[Catch2](https://github.com/catchorg/Catch2) and [Doctest](https://github.com/onqtam/doctest).

To declare tests, one must first declare a head target and an optional associated provider
through call to `gateau_setup_testing()`, then one can simply declare new test cases with
calls to `gateau_add_test()`.

```
gateau_setup_testing(<target> [GTEST|CATCH2|DOCTEST])

gateau_add_test(<test_name> [OPTIONS ACCEPTED BY gateau_add_executable()])
```

By declaring a provider, said provider gets installed for you if required, test cases get
linked to the provider and the test cases are integrated to the CTest framework.

### Other minor features

Some of the Gateau modules export a few other useful functions.

#### Grouping non source files into folders

`gateau_other_files(category files...)` can be used to group the list of files into
a folder named "category". For tidy grouping in the tree view of an IDE.

This has not be tested apart from Qt Creator.

#### Qt Related tools

The `GateauQtHelpers` module contains a few helpers to work with Qt related projects.
This has not been used and tested enough to warrant any documentation.

