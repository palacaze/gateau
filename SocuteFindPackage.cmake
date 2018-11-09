# This module proposes a streamlined way of handling external package dependencies.

include(SoCuteHelpers)
include(SoCuteSystemVars)

# List directories in ${dir} and them the CMAKE_PREFIX_PATH
# Theses directories contain external packages installed in their own prefix dir.
function(socute_update_prefix_path dir)
    # Find packages directories
    file(GLOB package_prefixes LIST_DIRECTORIES true "${dir}*")

    foreach(prefix ${package_prefixes})
        if (IS_DIRECTORY "${prefix}")
            socute_append_cached(CMAKE_PREFIX_PATH "${prefix}/prefix")

            # Search paths are restricted in the toolchain files in cross-compile mode,
            # however our prefix directories are safe to use so we allow to use it from find_*
            socute_append_cached(APPEND CMAKE_FIND_ROOT_PATH "${prefix}/prefix")
        endif()
    endforeach()
endfunction()

# Declare a dependency known by socute cmake modules (in the packages dir)
# This will be used later on to simplify installation and export of the package
function(socute_declare_known_dependency name repo)
    # record the package name for later in a cache variable
    socute_append_cached(SOCUTE_PACKAGE_KNOWN_DEP_MODULE ${repo})

    # record the command that was called to look for the package
    # put a ||| separator in the command because the cache file can't handle newlines
    list(JOIN ARGN " " args)
    string(CONFIGURE "include(@name@)|||pkg_find(@args@)" cmd @ONLY)
    socute_append_cached(SOCUTE_PACKAGE_KNOWN_DEP_CMD ${cmd})
endfunction()

# Declare a dependency unknown by socute cmake modules (in the packages dir)
# This will be used later on to simplify installation and export of the package
function(socute_declare_unknown_dependency)
    # record the command that was called to look for the package
    list(JOIN ARGN " " args)
    string(CONFIGURE "find_package(@args@)" cmd @ONLY)
    socute_append_cached(SOCUTE_PACKAGE_UNKNOWN_DEP_CMD ${cmd})
endfunction()

# Function that handles looking for packages and installing them in the right
# place if missing. It uses specially crafted modules (in the packages directory)
# containing directives that specify how to find and install said packages.
function(socute_find_package name)
    # We allow an OPTIONAL flag to mark a package as optional.
    # This means that the default behaviour is to require packages.
    # It won't be installed if not found.
    cmake_parse_arguments(SFP "OPTIONAL" "" "" ${ARGN})

    # Prepare pathes
    socute_find_rootdir(SOCUTE_EXTERNAL_DATA_DIR)
    socute_update_prefix_path("${SOCUTE_EXTERNAL_DATA_DIR}")
    set(SOCUTE_EXTERNAL_DATA_DIR "${SOCUTE_EXTERNAL_DATA_DIR}" CACHE INTERNAL "")

    # Look for the appropriate package module in the "packages" directory
    # If no package module is present but a package is obviously part of the SoCute
    # software collection, we generate a new module for it.
    set(module_path "${SOCUTE_CMAKE_MODULES_DIR}/packages/${name}.cmake")
    if (NOT EXISTS "${module_path}" AND ${name} MATCHES "^SoCute")
        # repo name is lowercase project name, "SoCute" excluded and with "-" between words
        string(REPLACE "SoCute" "" SOCUTE_PACKAGE_REPO_NAME "${name}")
        socute_to_snakecase(${SOCUTE_PACKAGE_REPO_NAME} SOCUTE_PACKAGE_REPO_NAME)
        string(REPLACE "_" "-" SOCUTE_PACKAGE_REPO_NAME "${SOCUTE_PACKAGE_REPO_NAME}")

        # generate module
        set(module_path "${CMAKE_BINARY_DIR}/gen-modules/${name}.cmake")
        set(SOCUTE_PACKAGE_MODULE_NAME ${name})
        configure_file("${SOCUTE_CMAKE_MODULES_DIR}/templates/SoCutePackage.cmake.in"
                       "${module_path}" @ONLY)
    endif()

    if (EXISTS "${module_path}")
        include("${module_path}")
        pkg_find(${SFP_UNPARSED_ARGUMENTS})

        # not found, we will try to install it and search again
        if (NOT ${name}_FOUND AND NOT SFP_OPTIONAL)
            # install missing dependency and update pathes
            pkg_install()
            socute_update_prefix_path("${SOCUTE_EXTERNAL_DATA_DIR}")

            # search again
            pkg_find(${SFP_UNPARSED_ARGUMENTS})
            if (NOT ${${name}_FOUND})
                message(FATAL_ERROR "Installation of package '${name}' failed.")
            endif()
        endif()

        # Register this package as a required dependency for software that will
        # use our project
        if (${${name}_FOUND})
            socute_declare_known_dependency(${name} ${module_path} ${SFP_UNPARSED_ARGUMENTS})
        endif()
    else()
        # Fallback to standard behaviour, this is not recommended
        message(WARNING "Unknown package '${name}'. Please consider adding a module for it.")
        if (NOT SFP_OPTIONAL)
            list(APPEND SPF_UNPARSED_ARGUMENTS "REQUIRED")
        endif()

        # Look for this package as we naturally would
        find_package(${name} ${SFP_UNPARSED_ARGUMENTS})

        # Register this package as a required dependency for software that will
        # use our project
        if (${${name}_FOUND})
            socute_declare_unknown_dependency(${name} ${SFP_UNPARSED_ARGUMENTS})
        endif()
    endif()
endfunction()
