#       Copyright Pierre-Antoine LACAZE 2018 - 2020.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

# This module declares function that considerably simplify project installation
include_guard()
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(GateauHelpers)

# Setup install location if not already set
function(gateau_setup_install_prefix)
    if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        # Find out where to install stuff
        gateau_external_install_prefix(install_prefix)
        set(CMAKE_INSTALL_PREFIX "${install_prefix}" CACHE PATH
            "Install path prefix, prepended onto install directories." FORCE)
    endif()
endfunction()

# Wrap native install() to overwrite DESTINATION with our custom prefix if needed
function(gateau_install)
    set(mono_options TYPE DESTINATION)
    set(multi_options FILES DIRECTORY)

    cmake_parse_arguments(SI "" "${mono_options}" "${multi_options}" ${ARGN})

    if (NOT SI_DESTINATION)
        message(FATAL_ERROR "The DESTINATION argument of gateau_install is missing")
    endif()

    # ensure a proper install prefix is none was given
    gateau_setup_install_prefix()

    set(args ${SI_UNPARSED_ARGUMENTS})

    list(INSERT args 0 DESTINATION "${SI_DESTINATION}")

    if (SI_TYPE)
        list(INSERT args 0 TYPE "${SI_TYPE}")
    endif()

    if (SI_DIRECTORY)
        list(INSERT args 0 DIRECTORY ${SI_DIRECTORY})
    endif()

    if (SI_FILES)
        list(INSERT args 0 FILES ${SI_FILES})
    endif()

    install(${args})
endfunction()

# Function to use once at the end of the main CMakeLists.txt to declare the
# project as installable and exportable
function(gateau_install_project)
    set(targets_name "${PROJECT_NAME}Targets")
    set(targets_file "${targets_name}.cmake")
    set(config_file  "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake")
    set(version_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
    set(cmake_dir    "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

    # ensure a proper install prefix is none was given
    gateau_setup_install_prefix()

    # list exported targets
    gateau_get(KNOWN_TARGETS targets)
    set(exported_targets)
    foreach(t ${targets})
        if (TARGET ${t})
            get_target_property(no_export ${t} no_export)
            # a target existing previously may have been removed
            if (NOT no_export)
                list(APPEND exported_targets ${t})
            endif()
        endif()
    endforeach()

    if (NOT exported_targets)
        message(STATUS "No target to export, skipping install of ${PROJECT_NAME}")
        return()
    endif()

    # Install the Targets file
    gateau_get(NAMESPACE nspace)
    install(
        EXPORT ${targets_name}
        FILE "${targets_file}"
        NAMESPACE ${nspace}::
        DESTINATION "${cmake_dir}"
        COMPONENT devel
    )

    gateau_get(TEMPLATES_DIR templates)
    configure_package_config_file(
        "${templates}/PackageConfig.cmake.in"
        "${config_file}"
        INSTALL_DESTINATION "${cmake_dir}"
    )

    # Create the Version file
    write_basic_package_version_file(
        "${version_file}"
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY AnyNewerVersion
    )

    # Install the Config and ConfigVersion FILES as well as the module
    # with the instructions to find dependencies
    gateau_get(DEP_DIR _dep_dir)
    set(_dep_module "${_dep_dir}/${PROJECT_NAME}FindDeps.cmake")
    install(
        FILES "${version_file}"
              "${config_file}"
              "${_dep_module}"
        DESTINATION "${cmake_dir}"
        COMPONENT devel
    )

    # Create the export-set file for our targets
    export(
        TARGETS ${exported_targets}
        NAMESPACE ${nspace}::
        FILE "${targets_file}"
    )
endfunction()
