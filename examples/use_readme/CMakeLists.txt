# A project that uses the library exported in the readme example.

cmake_minimum_required(VERSION 3.15)

project(gourmand LANGUAGES CXX)

# We include Gateau
include("${CMAKE_CURRENT_SOURCE_DIR}/../../Gateau.cmake")

# gateau_configure() is optional

# Looking for eclair, which was previously compiled and installed
gateau_find_package(eclair)

# Creating our program
gateau_add_executable(gourmand
    SOURCES main.cpp
    LINK_LIBRARIES eclair::lib
)
