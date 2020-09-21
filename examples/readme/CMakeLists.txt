# This is an Example project

cmake_minimum_required(VERSION 3.15)

# Project definition
project(eclair
    VERSION 0.1
    DESCRIPTION "A yummy project"
    HOMEPAGE_URL "https://www.yummy-eclair.pro"
    LANGUAGES CXX
)

# We include Gateau
include("${CMAKE_CURRENT_SOURCE_DIR}/../../Gateau.cmake")

# Configure gateau
gateau_configure(
    EXTERNAL_ROOT "${PROJECT_BINARY_DIR}/3rdparty"
    OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/bin"
    GENERATED_HEADER_CASE HYPHEN
    GENERATED_HEADER_EXT hpp
)

# Looking for fmtlib
gateau_find_package(fmt GIT https://github.com/fmtlib/fmt)

# The main sources
add_subdirectory(src)

# Tests
if (ECLAIR_BUILD_TESTS)
    add_subdirectory(test)
endif()

# Documentation
if (ECLAIR_BUILD_DOC)
    gateau_build_documentation(
        EXCLUDED_SYMBOLS
            detail  # exclude "detail" namespace
            _*      # and symbols starting with a "_"
    )
endif()

# Other files we would like to see in the IDE
file(GLOB_RECURSE _doc_files "doc/*.md")
gateau_other_files(Doc
    README.md
    ${_doc_files}
)

# Installation
gateau_install_project()

