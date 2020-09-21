#       Copyright Pierre-Antoine LACAZE 2018 - 2020.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

# This module is the main entry point of Gateau's cmake modules distribution.
# It should be included right after the call to project() in the top level
# CMakeLists.txt of a project.

# Enforce minimum version
if (CMAKE_MINIMUM_REQUIRED_VERSION VERSION_LESS "3.15")
    cmake_minimum_required(VERSION 3.15)
endif()

# Guard against in-source builds
if (CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_CURRENT_BINARY_DIR)
    message(FATAL_ERROR "In-source builds not allowed. Please make a new directory\n
                         (called a build directory) and run CMake from there.\n
                         You may need to remove CMakeCache.txt.")
endif()

if (NOT DEFINED PROJECT_NAME)
    message(FATAL_ERROR "project() must be called prior to Gateau inclusion")
endif()

if (NOT CMAKE_CURRENT_LIST_DIR IN_LIST CMAKE_MODULE_PATH)
    list(PREPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
endif()

# Include the other modules
include(GateauHelpers)
include(GateauCompilerOptions)
include(GateauConfigure)
include(GateauAddTarget)
include(GateauAddTest)
include(GateauQtHelpers)
include(GateauFindPackage)
include(GateauDoxygen)
include(GateauInstallProject)

gateau_init()
