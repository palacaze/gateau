# This module defines wrapper macros that supplement CMake macros with additional
# features that simplifies the creation of fully comfigured targets.
#
# Diverses CMake options are defined here and can be used project-wide to alter
# the behaviour of those macros.

# options that can alter the behaviour of the macros to follow
option(SOCUTE_ENABLE_AUTOSELECT_LINKER "Select the best available linker" ON)
option(SOCUTE_ENABLE_COMMON_WARNINGS "Enable common compiler flags" ON)
option(SOCUTE_ENABLE_LIBCXX "Use libc++ instead of gcc standard library" OFF)
option(SOCUTE_ENABLE_LTO "Enable link time optimization (release only)" OFF)
option(SOCUTE_ENABLE_MANY_WARNINGS "Enable more compiler warnings" OFF)
option(SOCUTE_ENABLE_PROFILING "Add compile flags to help with profiling" OFF)
option(SOCUTE_SANITIZE_ADDRESS "Compile with address sanitizer support" OFF)
option(SOCUTE_SANITIZE_THREADS "Compile with thread sanitizer support" OFF)
option(SOCUTE_SANITIZE_UNDEFINED "Compile with undefined sanitizer support" OFF)
option(SOCUTE_KEEP_TEMPS "keep temporary compiler-generated files for debugging purpose" OFF)

include(CMakeParseArguments)
include(GenerateExportHeader)
include(SoCuteHelpers)

# default defines
if (WIN32)
    list(APPEND SOCUTE_DEFAULT_DEFINES UNICODE _UNICODE _CRT_SECURE_NO_WARNINGS WIN32_LEAN_AND_MEAN)
endif()

# for vcs information
find_package(Git)

# Function that creates a header with metadata information
function(socute_generate_version_header name out)
    socute_target_full_name(${name} target_name)
    socute_target_identifier_name(${name} target_id)

    set(SOCUTE_BASE_NAME ${target_id})
    set(SOCUTE_TARGET_NAME ${target_name})
    set(SOCUTE_PROJECT_REVISION unknown)
    if (GIT_FOUND)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --always
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            OUTPUT_VARIABLE SOCUTE_PROJECT_REVISION
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif()

    socute_generated_dir(gendir)
    set(header_out "${gendir}/${name}Version.h")
    configure_file("${SOCUTE_CMAKE_MODULES_DIR}/templates/version.h.in"
                   "${header_out}" @ONLY)
    set(${out} "${header_out}" PARENT_SCOPE)
endfunction()

# add public include dirs to a target
function(socute_set_public_includes target includes)
    foreach(inc_dir IN LISTS includes)
        if (NOT IS_ABSOLUTE ${inc_dir})
            set(inc_dir "${CMAKE_CURRENT_SOURCE_DIR}/${inc_dir}")
        endif()
        target_include_directories(${target} PUBLIC $<BUILD_INTERFACE:${inc_dir}>)
    endforeach()
endfunction()

# Function that sets common properties to lib or exec targets
function(socute_set_properties alias target target_id)
    # compile flags
    # set_target_properties(${target} PROPERTIES CXX_EXTENSIONS NO)
    # target_compile_features(${target} PRIVATE cxx_std_14)

    # add the src dir to the include directories
    target_include_directories(${target} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src>
        $<INSTALL_INTERFACE:include>
    )

    # account for options
    target_link_libraries(${target} PRIVATE
        $<$<BOOL:${SOCUTE_ENABLE_COMMON_WARNINGS}>:SoCute_CommonWarnings>
        $<$<BOOL:${SOCUTE_KEEP_TEMPS}>:SoCute_SaveTemps>
        $<$<BOOL:${SOCUTE_ENABLE_LIBCXX}>:SoCute_Libcxx>
        $<$<BOOL:${SOCUTE_ENABLE_MANY_WARNINGS}>:SoCute_HighWarnings>
        $<$<BOOL:${SOCUTE_ENABLE_PROFILING}>:SoCute_Profiling>
        $<$<BOOL:${SOCUTE_SANITIZE_ADDRESS}>:SoCute_AddressSanitizer>
        $<$<BOOL:${SOCUTE_SANITIZE_THREADS}>:SoCute_ThreadSanitizer>
        $<$<BOOL:${SOCUTE_SANITIZE_UNDEFINED}>:SoCute_UndefinedSanitizer>
    )

    if (UNIX AND SOCUTE_COMPILER_CLANG_OR_GCC)
        target_link_libraries(${target} PRIVATE
            $<$<BOOL:${SOCUTE_ENABLE_AUTOSELECT_LINKER}>:SoCute_Linker>
        )
    endif()

    if (SOCUTE_ENABLE_LTO)
        set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION ON)
    endif()

    # default to hidden to catch symbol export problems
    set_target_properties(${target} PROPERTIES
        $<$<CONFIG:Release>:C_VISIBILITY_PRESET hidden>
        $<$<CONFIG:Release>:CXX_VISIBILITY_PRESET hidden>
        $<$<CONFIG:Release>:VISIBILITY_INLINES_HIDDEN 1>
    )

    socute_generate_version_header(${alias} out)
endfunction()

# Function that creates a new library, the first argument must be either a module
# name for multi libraries projects, or exactly the package name if there is only
# one library to be built. That way for multi libraries, the library will be
# called OrgaPackageMod and aliased to Orga::PackageMod, and for single library
# projects it will be called OrgaPackage and aliased to Orga::Package
function(socute_add_library lib)
    socute_target_export_name(${lib} export_name)
    socute_target_full_name(${lib} target_name)
    socute_target_alias_name(${lib} target_alias)
    socute_target_identifier_name(${lib} target_identifier)

    # create the library
    add_library(${target_name} ${ARGN})
    add_library(${target_alias} ALIAS ${target_name})

    # record the list of libraries in a property
    # TODO: Check if lib already exists in list and throw fatal error ?
    set_property(GLOBAL APPEND PROPERTY SOCUTE_LIBRARY_LIST ${lib})

    # ensure a proper version and short name
    set_target_properties(${target_name} PROPERTIES
        VERSION ${PROJECT_VERSION}
        EXPORT_NAME ${export_name}
    )

    # export header
    socute_generated_dir(gendir)
    generate_export_header(${target_name}
        BASE_NAME ${target_identifier}
        EXPORT_FILE_NAME ${gendir}/${lib}Export.h
    )
    if (NOT BUILD_SHARED_LIBS)
        target_compile_definitions(${target_name} PRIVATE ${target_identifier}_STATIC_DEFINE)
    endif()

    # common properties
    socute_set_properties(${lib} ${target_name} ${target_identifier})
endfunction()

# Add a plugin, a library declared as a module in cmake parlance
function(socute_add_plugin lib)
    socute_add_library("${lib}" MODULE ${ARGN})
endfunction()

# Function that creates a new executable, the first argument must the name short
# executable name, which will be appended to the package name to form the full
# target name.
function(socute_add_executable exe)
    socute_target_export_name(${exe} export_name)
    socute_target_full_name(${exe} target_name)
    socute_target_alias_name(${exe} target_alias)
    socute_target_identifier_name(${exe} target_identifier)

    # create the executable
    add_executable(${target_name} ${ARGN})

    set_target_properties(${target_name} PROPERTIES
        EXPORT_NAME ${export_name}
        OUTPUT_NAME ${exe}
    )

    # common properties
    socute_set_properties(${exe} ${target_name} ${target_identifier})
endfunction()
