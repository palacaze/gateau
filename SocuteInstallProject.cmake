# This module declares function that considerably simplify project installation

include(SocuteHelpers)
include(SocuteConfig)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# Setup install location if not already set
function(_socute_setup_install_prefix)
    if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        # Find out where to install stuff
        socute_to_target("${SOCUTE_PACKAGE}" projectname_target)
        socute_external_install_dir("${projectname_target}" install_dir)
        set(CMAKE_INSTALL_PREFIX "${install_dir}" CACHE PATH
            "Install path prefix, prepended onto install directories." FORCE)
    endif()
endfunction()

# This function should be called for every target that needs to be installed
# It basically declares the target as installable and also installs headers
# for library targets.
# It must be called from the same cmake file that created the target.
#
# The following options are offered:
# - BINARY_ONLY to only install binaries
# - INSTALL_BINDIR to override the binaries installation directory
# - INSTALL_LIBDIR to override the libraries installation directory
# - INSTALL_INCLUDEDIR to override the headers installation directory
function(socute_install_target alias)
    set(opts BINARY_ONLY INSTALL_BINDIR INSTALL_LIBDIR INSTALL_INCLUDEDIR)
    cmake_parse_arguments(SIT "" "${opts}" "" ${ARGN})

    _socute_setup_install_prefix()

    if (NOT SIT_INSTALL_BINDIR)
        set(SIT_INSTALL_BINDIR "${CMAKE_INSTALL_BINDIR}")
    endif()

    if (NOT SIT_INSTALL_LIBDIR)
        set(SIT_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}")
    endif()

    if (NOT SIT_INSTALL_INCLUDEDIR)
        set(SIT_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()

    # rpath
    socute_append_cached(CMAKE_INSTALL_RPATH "$ORIGIN/../${SIT_INSTALL_LIBDIR}")

    socute_target_full_name(${alias} target)
    socute_to_target("${SOCUTE_PACKAGE}" projectname_target)
    set(targets_name "${projectname_target}Targets")

    # for libraries, we must install headers and declare a component
    get_target_property(target_type ${target} TYPE)

    if (target_type STREQUAL EXECUTABLE)
        # Declare where the target must be installed and in which export-set to put it
        install(
            TARGETS ${target}
            EXPORT ${targets_name}
            RUNTIME DESTINATION ${SIT_INSTALL_BINDIR} COMPONENT ${alias}
        )

    else()
        # Declare where the target must be installed and in which export-set to put it
        install(
            TARGETS ${target}
            EXPORT ${targets_name}
            RUNTIME DESTINATION ${SIT_INSTALL_BINDIR} COMPONENT ${alias}
            LIBRARY DESTINATION ${SIT_INSTALL_LIBDIR} COMPONENT ${alias}
            ARCHIVE DESTINATION ${SIT_INSTALL_LIBDIR} COMPONENT ${alias}
        )

        # Install headers if they are requested
        if (NOT SIT_BINARY_ONLY)
            # get a list of headers for this particular target
            get_target_property(sources ${target} SOURCES)
            list(FILTER sources INCLUDE REGEX ".+\\.h?(h|pp)$")

            # install them while respecting the original filesystem structure
            # We are forced to install every file manually because the function
            # install(DIRECTORY) cannot select headers for one target and the
            # install(TARGET PUBLIC_HEADER) does not respect the filesystem structure
            foreach(header ${sources})
                if (NOT IS_ABSOLUTE header)
                    set(header "${CMAKE_CURRENT_SOURCE_DIR}/${header}")
                endif()

                # Headers will be installed relative to the "src" directory, we calculate
                # the relative path name to append to the install prefix.
                get_filename_component(header_relpath "${header}" DIRECTORY)
                file(RELATIVE_PATH header_relpath "${CMAKE_SOURCE_DIR}/src" "${header_relpath}")

                install(
                    FILES "${header}"
                    DESTINATION "${SIT_INSTALL_INCLUDEDIR}/${header_relpath}"
                    COMPONENT ${alias}
                )
            endforeach()

            # also install generated headers
            socute_generated_dir(gendir)
            socute_to_subfolder("${SOCUTE_PACKAGE}" package_subfolder)
            install(
                FILES "${gendir}/${alias}Export.h"
                      "${gendir}/${alias}Version.h"
                DESTINATION "${SIT_INSTALL_INCLUDEDIR}/${package_subfolder}"
                COMPONENT ${alias}
            )
        endif()
    endif()

    # mark the target as installable
    socute_append_cached(SOCUTE_PACKAGE_KNOWN_TARGETS ${target})
endfunction()

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

# function to use once at the end of the main CMakeLists.txt to really install things
function(socute_install_project)
    socute_to_target("${SOCUTE_PACKAGE}" projectname_target)

    set(targets ${SOCUTE_PACKAGE_KNOWN_TARGETS})
    set(namespace ${SOCUTE_PACKAGE_EXPORT_NAMESPACE})
    set(targets_name "${projectname_target}Targets")
    set(targets_file "${targets_name}.cmake")
    set(config_file  "${CMAKE_CURRENT_BINARY_DIR}/${projectname_target}Config.cmake")
    set(version_file "${CMAKE_CURRENT_BINARY_DIR}/${projectname_target}ConfigVersion.cmake")
    set(cmake_dir    "${CMAKE_INSTALL_LIBDIR}/cmake/${projectname_target}")

    # Install the Targets file
    install(
        EXPORT ${targets_name}
        FILE ${targets_file}
        NAMESPACE ${namespace}::
        DESTINATION ${cmake_dir}
        COMPONENT ${projectname_target}Export
    )

    # copy the modules we used to find dependencies, they will be reused
    foreach(mod ${SOCUTE_PACKAGE_CONFIG_FIND_MODULE})
        install(FILES "${mod}" DESTINATION ${cmake_dir})
    endforeach()

    # Create the Config file
    # We rely on the information gathered from the calls to socute_find_package
    # to generate a Config file that looks for the appropriate dependencies
    list(JOIN SOCUTE_PACKAGE_CONFIG_FIND_CMD "\n" SOCUTE_PACKAGE_CONFIG_FIND_CMDS)
    string(REPLACE "|||" "\n" SOCUTE_PACKAGE_CONFIG_FIND_CMDS "${SOCUTE_PACKAGE_CONFIG_FIND_CMDS}")

    configure_package_config_file(
        ${SOCUTE_CMAKE_MODULES_DIR}/templates/PackageConfig.cmake.in
        ${config_file}
        INSTALL_DESTINATION ${cmake_dir}
    )

    # Create the Version file
    write_basic_package_version_file(
        ${version_file}
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY AnyNewerVersion
    )

    # Install the Config and ConfigVersion files
    install(
        FILES ${version_file}
              ${config_file}
        DESTINATION ${cmake_dir}
        COMPONENT ${projectname_target}Export
    )

    # create the export-set file for our targets
    export(
        TARGETS ${targets}
        NAMESPACE ${namespace}::
        FILE ${targets_file}
    )
endfunction()
