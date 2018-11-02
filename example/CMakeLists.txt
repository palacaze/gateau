cmake_minimum_required(VERSION 3.12.0)

project(CmakeExample
    VERSION 0.0.1
    DESCRIPTION "SoCute Cmake modules example"
    HOMEPAGE_URL "https://gitlab.pasnox.com:9443/so-cute/cmake-modules"
    LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/..)

# add socute main cmake module
include(SoCute)

add_subdirectory(src)
