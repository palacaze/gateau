# This module is the main entry point of SoCute's cmake modules distribution.
# It should be include near the top of each project's top level CMakeLists.txt.

# Guard against in-source builds
if (CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(FATAL_ERROR "In-source builds not allowed. Please make a new directory\n
                         (called a build directory) and run CMake from there.\n
                         You may need to remove CMakeCache.txt.")
endif()

# Set a variable with the path of the present module
set(SOCUTE_CMAKE_MODULES_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

# Default build type
if (NOT DEFINED CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
endif()

# Satic or Shared libraries
# if the library type is not provided, we create static libraries in release mode
# and dynamic libraries otherwise (linking is slow in debug, so we minimize it).
if (NOT DEFINED BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS $<CONFIG:Release>)
endif()

# Misc make options
set(CMAKE_COLOR_MAKEFILE ON)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Needed for Qt automoc before cmake 3.8
if (CMAKE_VERSION VERSION_LESS 3.8)
    set(CMAKE_INCLUDE_CURRENT_DIR ON)
endif()

# set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE})
# set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE})
# set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE})

# Compiler type
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(SOCUTE_COMPILER_CLANG ON)
elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(SOCUTE_COMPILER_GCC ON)
endif()

set(SOCUTE_COMPILER_CLANG_OR_GCC ${SOCUTE_COMPILER_CLANG} OR ${SOCUTE_COMPILER_GCC})

# 32 or 64 bits
if (CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
    set(SOCUTE_X64 ON)
    set(SOCUTE_X32 OFF)
else()
    set(SOCUTE_X64 OFF)
    set(SOCUTE_X32 ON)
endif()

include(SoCuteCompilerOptions)
include(SoCuteHelperMacros)

