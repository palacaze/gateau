# This module declares function that considerably simplify project installation

include(SoCuteHelpers)
include(SoCuteSystemVars)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# This function should be called for every target that needs to be installed
# It basically declares the target as installable and also installed headers
# for library targets
function(socute_install_target alias)
    # Set default install location if not already set
    if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        # Find out where to install stuff
        socute_get_install_root(install_root)
        set(CMAKE_INSTALL_PREFIX "${install_root}/${PROJECT_NAME}/prefix" CACHE PATH
            "Install path prefix, prepended onto install directories." FORCE)
    endif()

    # rpath
    socute_append_cached(CMAKE_INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")

    socute_target_full_name(${alias} target)
    set(targets_name "${PROJECT_NAME}Targets")

    # for libraries, we must install headers and declare a component
    get_target_property(target_type ${target} TYPE)

    if (target_type STREQUAL EXECUTABLE)
        # Declare where the target must be installed and in which export-set to put it
        install(
            TARGETS ${target}
            EXPORT ${targets_name}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${alias}
        )

    else()
        # Declare where the target must be installed and in which export-set to put it
        install(
            TARGETS ${target}
            EXPORT ${targets_name}
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR} COMPONENT ${alias}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${alias}
            ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR} COMPONENT ${alias}
            INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
        )

        # Headers will be installed relative to the "src" directory, we calculate
        # the relative path name to append to the install prefix.
        file(RELATIVE_PATH headers_relpath "${CMAKE_SOURCE_DIR}/src" "${CMAKE_CURRENT_SOURCE_DIR}/")

        # Get the list of headers of the target, those will be installed
        install(
            DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/"
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${headers_relpath}"
            COMPONENT ${alias}
            FILES_MATCHING REGEX ".+\\.h?(h|pp)$"
        )

        socute_generated_dir(gendir)
        install(
            FILES ${headers}
                  "${gendir}/${alias}Export.h"
                  "${gendir}/${alias}Version.h"
            DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/${SOCUTE_ORGANIZATION}/${SOCUTE_PACKAGE}"
            COMPONENT ${alias}
        )
    endif()

    # mark the target as installable
    socute_append_cached(SOCUTE_PACKAGE_KNOWN_TARGETS ${target})
endfunction()

# function to use once at the end of the main CMakeLists.txt to really
# install things
function(socute_install_project)
    set(targets ${SOCUTE_PACKAGE_KNOWN_TARGETS})
    set(namespace ${SOCUTE_ORGANIZATION})
    set(targets_name "${PROJECT_NAME}Targets")
    set(targets_file "${targets_name}.cmake")
    set(config_file  "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake")
    set(version_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake")
    set(cmake_dir    "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

    # Install the Targets file
    install(
        EXPORT ${targets_name}
        FILE ${targets_file}
        NAMESPACE ${namespace}::
        DESTINATION ${cmake_dir}
        COMPONENT ${PROJECT_NAME}Export
    )

    # copy the modules we used to find dependencies, they will be reused
    foreach(mod ${SOCUTE_PACKAGE_KNOWN_DEP_MODULE})
        install(FILES "${mod}" DESTINATION ${cmake_dir})
    endforeach()

    # Create the Config file
    # We rely on the information gathered from the calls to socute_find_package
    # to generate a Config file that looks for the appropriate dependencies
    list(JOIN SOCUTE_PACKAGE_KNOWN_DEP_CMD "\n" SOCUTE_PACKAGE_FIND_DEP_CMDS)
    string(REPLACE "|||" "\n" SOCUTE_PACKAGE_FIND_DEP_CMDS "${SOCUTE_PACKAGE_FIND_DEP_CMDS}")

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
        COMPONENT ${PROJECT_NAME}Export
    )

    # create the export-set file for our targets
    export(
        TARGETS ${full_targets}
        NAMESPACE ${namespace}::
        FILE ${targets_file}
    )

endfunction()
