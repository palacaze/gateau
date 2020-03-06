# Socute CMake Modules

This library consists in a set of CMake modules that make working with CMake both easier and safer. It has been developed for Socute projects at first, but is quite generic and can be used outside of Socute projects too.

It contains functions that make it very simple to create a project with dependencies and a few targets. In particular it is capable of:

- Setting up useful options to make c++ development a breeze: reasonable compiler options, sanitizers integration, on demand lto and ccache utilization...
- Looking for dependencies, downloading, compiling and installing them if missing with minimal syntax overhead,
- Declaring new targets that will be configured in a sensible way for you to make it both installable and importable. An export header and versioning header get generated for every target.
- Making target trivially installable in a uniform way, with automatic installation of binaries, headers as well as generation of CMake config, version and target modules so that your project can be found and used by other projects.
- Declaring tests in a simple way,
- Automatically generating Doxygen documentation,
- Generating translation files for Qt based projects.

Below is a breakdown of the features and example code to explain how to use them.

## Before you start: conventions that the project should follow

### CMake version

CMake version 3.14 or later is mandatory, as Socute modules relies on modern CMake constructs to achieve its goals.

### Naming conventions

We distinguish the following three parts used to name things:

- An optional Organization name, that shelters several projects under a common name prefix,
- A Project name, that uniquely identifies the current project,
- One or several target names, that will be built by the project.

The Organization and Project names are defined by calling the `socute_project()` function.
Every target will be created by a call to either `socute_add_library()`, `socute_add_module()` or `socute_add_executable()`.

The following table recapitulates how things get named when using Socute cmake modules.

| Name | Meaning |
|------|---------|
| Orga | Organization name |
| Project | Shorthand project name declared in socute_project() |
| Target | Shorthand target name declared in socute_add_lib/exe/mod and expected to be passed to socute api requiring a target name |
| Orga::Project | Full project name |
| OrgaProject | Name of the exported package when calling CMake find_pakage() |
| OrgaProjectTarget | Full target name, this is the name to use when passing the target name to a cmake API |
| OrgaTarget | Simplified full target name if one declares a target with the same name than the project |
| Orga::Project::Target | Full target name alias that gets exported, to be used for linking |
| Orga::Target | Full target name alias that gets exported when Project name == Target name |

### File system structure

Here is the recommended file system layout:

```
.
├── CMakeLists.txt
├── data
│  └── Misc.svg
├── example
│  ├── CMakeLists.txt
│  ├── Example1.cpp
│  └── Example2.cpp
├── README.md
├── src
│  └── Organization
│     ├── CMakeLists.txt
│     └── Project
│        ├── File.h
│        ├── File.cpp
│        └── Header.h
└── test
   ├── CMakeLists.txt
   ├── Test1.cpp
   └── Test2.cpp
```

The source code for the project is expected to be placed in the  src/Organization/Project directory and subdirectories. Only "src" is mandatory, but header files installation will follow the directory structure of the source code, so if one wants a nice headers layout, the above recommendation should be followed.

Tests and examples should be placed in directories whose name is "test" and "example", mind the lack of plural. The reason lies in the fact that CMake automatically creates mock targets for every directory name. So if we want the "tests" and "examples" target to be available for compiling those, we must avoid directory names with the exact same name (hence the singular).

## Declaring a project

Before declaring anything, the top level CMakeLists.txt must declare a minimum version and include Socute CMake module. This must appear at the top of the file.
Let's assume Socute modules lie in a socute-cmake directory in the root of the project, we expect the following:

```
cmake_minimum_required(VERSION 3.14)

# Configure Socute cmake modules before import
# set(SOCUTE_EXTERNAL_ROOT "$ENV{HOME}/code/external")
# set(SOCUTE_EXTERNAL_BUILD_TYPE Release)
# set(SOCUTE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin")

# Make Socute modules available to CMake
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/socute-cmake")

# Include all the Socute modules
include(Socute)

# Declare the project
socute_project(Project
    VERSION 0.1
    ORGANIZATION Orga
    DESCRIPTION "My great Project"
    HOMEPAGE_URL "https://project.orga.com"
    LANGUAGES C CXX
)
```

`socute_project` expects a project name as first argument, a few mandatory named arguments (VERSION, DESCRIPTION and HOMEPAGE). ORGANIZATION is optional and the other named arguments will be forwarded to the raw CMake `project` function.

## Finding dependencies

## Adding targets

## Making a target/project installable

## Generating documentation

## Adding tests

## Qt Helpers

## API

### Options

### Functions

