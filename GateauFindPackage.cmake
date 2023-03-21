#       Copyright Pierre-Antoine LACAZE 2018 - 2020.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

# This module proposes a streamlined way of handling external package dependencies.
include_guard()
include(GateauHelpers)

# Add a directory to the list of directories to search when looking for a
# package module file with installation instructions inside of it
function(gateau_add_package_module_dir dir)
    gateau_prepend(PACKAGE_MODULES_DIRS "${dir}")
endfunction()

# Look for a PostFind module for the given dependency name.
function(_gateau_get_postfind_module name modfile)
    # If found, the postfind module will be copied in the DEP_DIR
    gateau_get(DEP_DIR _dep_dir)
    set(_pf_dir "${_dep_dir}/postfind")
    gateau_create_dir("${_pf_dir}")

    # Look in each package directory for PostFind${name}.cmake
    gateau_get(PACKAGE_MODULES_DIRS _mod_dirs)
    foreach (dir ${_mod_dirs})
        set(module_path "${dir}/PostFind${name}.cmake")
        if (EXISTS "${module_path}")
            file(COPY "${module_path}" DESTINATION "${_pf_dir}")
            set(${modfile} "${_pf_dir}/PostFind${name}.cmake" PARENT_SCOPE)
            break()
        endif()
    endforeach()
endfunction()

# Append find and postfind instructions for this dep to a module that will be
# installed along with the project.
function(_gateau_register_dep name modfile)
    list(JOIN ARGN " " args)

    # The main dependency module
    gateau_get(DEP_DIR _dep_dir)
    set(_dep_module "${_dep_dir}/${PROJECT_NAME}FindDeps.cmake")
    if (NOT EXISTS "${_dep_module}")
        file(APPEND "${_dep_module}" "include(CMakeFindDependencyMacro)\n")
    endif()

    # find the dependency
    string(CONFIGURE "find_dependency(@name@ @args@)" cmd @ONLY)
    file(APPEND "${_dep_module}" "${cmd}\n")

    # post configure
    if (EXISTS "${modfile}")
        file(APPEND "${_dep_module}" "include(\"postfind/PostFind${name}.cmake\")\n")
    endif()
endfunction()

# Macro that handles looking for packages and registering which where found.
# It also applies "PostFind" modules (in the packages directory) to adjust or
# improve over existing CMake modules. For instance adding a compile definition.
#
# NOTE: We use a macro because find_package() creates variables such as:
# ${package}_FOUND cached and would be unavailable if created inside a function.
macro(gateau_find_package name)
    cmake_parse_arguments(_O "OPTIONAL;BUILD_ONLY_DEP" "" "" ${ARGN})

    set(_o_required)
    if (NOT _O_OPTIONAL)
        set(_o_required REQUIRED)
    endif()

    # try to find the dependency
    find_package(${name} ${_O_UNPARSED_ARGUMENTS} ${_o_required})

    # Load optional modules used to fix, correct or improve a dependency
    # Try to find the "PostFind" package file that contains instructions on how
    # to fix, correct or improve a package, then source it.
    _gateau_get_postfind_module(${name} _postfind_mod)
    if (EXISTS "${_postfind_mod}")
        include("${_postfind_mod}")
    endif()

    # Register this package as a required dependency for software that will use
    # our project, unless it has been marked as a build-only dep.
    if (${name}_FOUND AND NOT _O_BUILD_ONLY_DEP)
        _gateau_register_dep(${name} "${_package_file}" ${_O_UNPARSED_ARGUMENTS})
    endif()

    # We are a macro, unset everything
    gateau_cleanup_parsed(_O "OPTIONAL;BUILD_ONLY_DEP" "" "")
    unset(_o_required)
    unset(_postfind_mod)
endmacro()
