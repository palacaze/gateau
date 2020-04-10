# This module declares function that considerably simplify project installation
include_guard()
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(SocuteHelpers)

# Wrap native install() to overwrite DESTINATION with our custom prefix if needed
function(socute_install)
    set(mono_options TYPE DESTINATION)
    set(multi_options FILES DIRECTORY)

    cmake_parse_arguments(SI "" "${mono_options}" "${multi_options}" ${ARGN})

    if (NOT SI_DESTINATION)
        message(FATAL_ERROR "The DESTINATION argument of socute_install is missing")
    endif()

    _socute_setup_install_prefix()

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
function(socute_install_project)
    set(targets_name "${PROJECT_NAME}Targets")
    set(targets_file "${targets_name}.cmake")
    set(config_file  "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake")
    set(version_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
    set(cmake_dir    "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

    # list exported targets
    socute_get_project_var(KNOWN_TARGETS targets)
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
    install(
        EXPORT ${targets_name}
        FILE "${targets_file}"
        NAMESPACE ${PROJECT_NAME}::
        DESTINATION "${cmake_dir}"
        COMPONENT ${PROJECT_NAME}_devel
    )

    # Copy the modules we used to find dependencies, they will be reused
    socute_get_project_var(FIND_PACKAGE_MODULES find_mods)
    install(FILES ${find_mods} DESTINATION "${cmake_dir}/deps")

    # Create the Config file
    # We rely on the information gathered from the calls to socute_find_package
    # to generate a Config file that looks for the appropriate dependencies
    socute_get_project_var(FIND_PACKAGE_COMMANDS find_cmds)
    list(JOIN find_cmds "\n" find_cmds)
    string(REPLACE "|||" "\n" SOCUTE_PACKAGE_CONFIG_FIND_PACKAGE_COMMANDS "${find_cmds}")

    socute_get_project_var(TEMPLATES_DIR templates)
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

    # Install the Config and ConfigVersion files
    install(
        FILES "${version_file}"
              "${config_file}"
        DESTINATION "${cmake_dir}"
        COMPONENT ${PROJECT_NAME}_devel
    )

    # Create the export-set file for our targets
    export(
        TARGETS ${exported_targets}
        NAMESPACE ${PROJECT_NAME}::
        FILE "${targets_file}"
    )
endfunction()
