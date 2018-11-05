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
