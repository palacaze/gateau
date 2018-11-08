# Compiler name
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(SOCUTE_COMPILER_CLANG ON)
    set(SOCUTE_COMPILER_NAME "clang")
elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(SOCUTE_COMPILER_GCC ON)
    set(SOCUTE_COMPILER_NAME "gcc")
elseif (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    set(SOCUTE_COMPILER_MSVC ON)
    set(SOCUTE_COMPILER_NAME "msvc")
endif()

if (SOCUTE_COMPILER_CLANG OR SOCUTE_COMPILER_GCC)
    set(SOCUTE_COMPILER_CLANG_OR_GCC ON)
endif()

# Compiler version
set(SOCUTE_COMPILER_VERSION "${CMAKE_CXX_COMPILER_VERSION}")

# System name
string(TOLOWER "${CMAKE_SYSTEM_NAME}" SOCUTE_SYSTEM_NAME)

# System version
if (SOCUTE_SYSTEM_NAME MATCHES "linux")
    # Special handling for linux, we want per distro name and appropriate version
    if (NOT DEFINED SOCUTE_SYSTEM_VERSION)
        # for linux we distinguish per distribution (flavour)
        find_program(LSB_RELEASE_EXEC lsb_release REQUIRED)

        execute_process(COMMAND ${LSB_RELEASE_EXEC} -is
            OUTPUT_VARIABLE SOCUTE_SYSTEM_FLAVOUR
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        string(TOLOWER "${SOCUTE_SYSTEM_FLAVOUR}" SOCUTE_SYSTEM_FLAVOUR)
        set(SOCUTE_SYSTEM_FLAVOUR ${SOCUTE_SYSTEM_FLAVOUR} CACHE INTERNAL "")

        execute_process(COMMAND ${LSB_RELEASE_EXEC} -rs
            OUTPUT_VARIABLE SOCUTE_SYSTEM_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(SOCUTE_SYSTEM_VERSION ${SOCUTE_SYSTEM_VERSION} CACHE INTERNAL "")
    endif()
else()
    set(SOCUTE_SYSTEM_FLAVOUR "${SOCUTE_SYSTEM_NAME}")
    set(SOCUTE_SYSTEM_VERSION "${CMAKE_SYSTEM_VERSION}")
endif()

# 32 or 64 bits
if (CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
    set(SOCUTE_X64 ON)
    set(SOCUTE_X32 OFF)
    set(SOCUTE_ARCH 64)
else()
    set(SOCUTE_X64 OFF)
    set(SOCUTE_X32 ON)
    set(SOCUTE_ARCH 32)
endif()

# Search for the root directory which will be used to install stuff for this
# particular compiler/system/config triplet.
# This path is composed of a SOCUTE_EXTERNAL_ROOT followed by the SYSTEM name/version,
# the compiler name-version and the config.
# SOCUTE_EXTERNAL_ROOT may be supplied to cmake at configure time, otherwise the
# environment variable of the same name will be picked. At last the fallback will
# be ${SOCUTE_BINARY_DIR}/external.
function(socute_find_rootdir dir)
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
