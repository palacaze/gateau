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
- Declaring new targets that will be configured in a sensible way for you to
  make it both installable and importable by other projects. An export header
  and version header get generated for every target.
- Making targets trivially installable, with automatic installation of binaries,
  headers as well as generation of CMake config, version and target modules so
  that your project can be found and used by other projects.
- Declaring tests in a simple way,
- Automatically generating Doxygen documentation,
- ...

Again, it is a simple tool, it does not handle dependency management. A package
manager such as vcpkg or conan should be used instead.

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
    OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin"
    GENERATED_HEADER_CASE HYPHEN
    GENERATED_HEADER_EXT hpp
)

# Looking for fmtlib
gateau_find_package(fmt)

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
            fmt::fmt-header-only
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

- Support Qt translations,
- Support Gitlab, Gihub automation,
- Automated project deployment and packaging, for instance with CPack,
- vcpkg integration,
- Add an option for configurable compiler flags.
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
| ${ID}_COMPILE_OPTIONS       | Additional compile options to apply               | ""                             |
| ${ID}_NAME_PREFIX           | The default prefix to use for output file names   | ""                             |
| ${ID}_LIBRARY_NAME_PREFIX   | The prefix to use for library output file names   | ""                             |
| ${ID}_RUNTIME_NAME_PREFIX   | The prefix to use for runtime output file names   | ""                             |


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

`${ID}_NAME_PREFIX`, `${ID}_LIBRARY_NAME_PREFIX` and `${ID}_RUNTIME_NAME_PREFIX`
can be used to add a custom prefix to the names of targets output names. For instance
a library target named `foo` with `${ID}_LIBRARY_NAME_PREFIX` set to 'bar' may be
named libbarfoo.so on some platforms.

`${ID}_C_STANDARD`, `${ID}_CXX_STANDARD` and `${ID}_COMPILE_OPTIONS` customize
compiler options to apply to all the targets of the project.

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
    [NAMESPACE <namespace>]
    [NAME_PREFIX <prefix>]
    [LIBRARY_NAME_PREFIX <library_prefix>]
    [RUNTIME_NAME_PREFIX <runtime_prefix>]
    [RELATIVE_HEADERS_DIRS [items...]])

```

The options are the same as described earlier, and allow the project developer
to tweak Gateau for the needs of the project.

### Finding dependencies

*Gateau* offers a wrapper over the find_packages facilities to keep track of
found dependencies and improve automated project installation.

To do so, simply replace calls to `find_package` with calls to `gateau_find_package`.

Gateau looks for "PostFind" modules which are sources after a package has been found
if the user wishes to improve or tweak a particular package. For instance some compile
definitions may be added to an imported target.
The name of such module must be `PostFind${Packagename}.cmake`

```
# Add a directory to the list of directories to search when looking for PostFind
# module file.
gateau_add_package_module_dir(<dir>)
```

```
gateau_find_package(<name>
    [OPTIONAL]
    [BUILD_ONLY_DEP])
```

Contrary to find_package, gateau_find_package defaults to `REQUIRED`. For optional
dependencies, the `OPTIONAL` keyword must be used.

#### Build-only dependencies

Some dependencies may be build-only deps, for instance headers-only libraries used
in private parts or code generation tools. The installed package does not depend on
it and as such does not constitute a runtime dependency. Those can be marked using
the `BUILD_ONLY_DEP` option, and will not be added to the package config module
installed with the package.

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
    [SYSTEM]
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
- SYSTEM: set the SYSTEM keywords to include directories
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
QtTest, [Catch2](https://github.com/catchorg/Catch2) and [Doctest](https://github.com/onqtam/doctest).

To declare tests, one must first declare a head target and an optional associated provider
through call to `gateau_setup_testing()`, then one can simply declare new test cases with
calls to `gateau_add_test()`.

```
gateau_setup_testing(<target> [GTEST|CATCH2|DOCTEST|QTTEST])

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

