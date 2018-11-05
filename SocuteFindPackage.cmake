# This module proposes a streamlined way of handling external package dependencies.

include(SoCuteSystemVars)

# Search for the root directory which will be used to install stuff for this
# particular compiler/system/config triplet.
# This path is composed of a SOCUTE_EXTERNAL_ROOT followed by the SYSTEM name/version,
# the compiler name-version and the config.
# SOCUTE_EXTERNAL_ROOT may be supplied to cmake at configure time, otherwise the
# environment variable of the same name will be picked. At last the fallback will
# be ${SOCUTE_BINARY_DIR}/external.
function(socute_find_data_dir dir)
    # Find the root directory
    if (NOT DEFINED "${SOCUTE_EXTERNAL_ROOT}")
        set(SOCUTE_EXTERNAL_ROOT "$ENV{SOCUTE_EXTERNAL_ROOT}")
        if (NOT "${SOCUTE_EXTERNAL_ROOT}")
            set(SOCUTE_EXTERNAL_ROOT "${CMAKE_BINARY_DIR}/external")
        endif()
    endif()

    # Compose full path
    set(sys "${SOCUTE_SYSTEM_FLAVOUR}-${SOCUTE_SYSTEM_VERSION}")
    set(comp "${SOCUTE_COMPILER_NAME}-${SOCUTE_COMPILER_VERSION}")
    set(datadir "${SOCUTE_EXTERNAL_ROOT}/${sys}/${comp}/${CMAKE_BUILD_TYPE}")

    # Ensure we can actually use this directory
    file(MAKE_DIRECTORY "${datadir}")
    if (NOT IS_DIRECTORY "${datadir}")
        message(FATAL_ERROR "Could not create directory ${datadir}")
    endif()

    set(${dir} "${datadir}" PARENT_SCOPE)
endfunction()

# List directories in ${dir} and them the CMAKE_PREFIX_PATH
# Theses directories contain external packages installed in their own prefix dir.
function(socute_append_prefix dir)
    # Find packages directories
    file(GLOB package_prefixes LIST_DIRECTORIES true *)
    foreach(prefix ${package_prefixes})
        if (IS_DIRECTORY "${prefix}")
            list(APPEND CMAKE_PREFIX_PATH "${prefix}/prefix")

            # Search paths are restricted in the toolchain files in cross-compile mode,
            # however our prefix directories are safe to use so we allow to use it from find_*
            list(APPEND CMAKE_FIND_ROOT_PATH "${prefix}/prefix")
        endif()
    endforeach()

    if (CMAKE_PREFIX_PATH)
        list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
    endif()
    if (CMAKE_FIND_ROOT_PATH)
        list(REMOVE_DUPLICATES CMAKE_FIND_ROOT_PATH)
    endif()
endfunction()

# Function that handles looking for packages and installing them in the right
# place if missing. It uses specially crafted modules (in the packages directory)
# containing directives that specify how to find and install said packages.
function(socute_find_package name)
    # We allow an OPTIONAL flag to mark a package as optional.
    # This means that the default behaviour is to require packages.
    # It won't be installed if not found.
    cmake_parse_arguments(SFP "OPTIONAL" "" "" ${ARGN})

    # prepare pathes
    socute_find_data_dir(SOCUTE_EXTERNAL_DATA_DIR)
    socute_append_prefix("${SOCUTE_EXTERNAL_DATA_DIR}")
    set(SOCUTE_EXTERNAL_DATA_DIR "${SOCUTE_EXTERNAL_DATA_DIR}" CACHE INTERNAL "")

    # Look for the appropriate package module in the "packages" directory
    set(module_path "${SOCUTE_CMAKE_MODULES_DIR}/packages/${name}.cmake")
    if (EXISTS "${module_path}")
        include("${module_path}")
        pkg_find(${SFP_UNPARSED_ARGUMENTS})

        if (NOT ${name}_FOUND AND NOT SFP_OPTIONAL)
            pkg_install()
            pkg_find(${SFP_UNPARSED_ARGUMENTS})
            if (NOT ${${name}_FOUND})
                message(FATAL_ERROR "Installation of package '${name}' failed.")
            endif()
        endif()
    else()
        # fallback to standard behaviour, this is not recommended
        message(WARNING "Unknown package '${name}'. Please consider adding a module for it.")
        if (NOT SFP_OPTIONAL)
            list(APPEND SPF_UNPARSED_ARGUMENTS "REQUIRED")
        endif()
        find_package(${name} ${SFP_UNPARSED_ARGUMENTS})
    endif()
endfunction()
