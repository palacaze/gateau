# This module defines wrapper macros that supplement CMake macros with additional
# features that simplifies the creation of fully comfigured targets.
#
# Diverses CMake options are defined here and can be used project-wide to alter
# the behaviour of those macros.

# options that can alter the behaviour of the macros to follow
option(SOCUTE_ENABLE_LIBCXX "Use libc++ instead of gcc standard library" OFF)
option(SOCUTE_ENABLE_LTO "Enable link time optimization (release only)" OFF)
option(SOCUTE_ENABLE_MANY_WARNINGS "Enable more compiler warnings" OFF)
option(SOCUTE_ENABLE_PROFILING "Add compile flags to help with profiling" OFF)
option(SOCUTE_SANITIZE_ADDRESS "Compile with address sanitizer support" OFF)
option(SOCUTE_SANITIZE_THREADS "Compile with thread sanitizer support" OFF)
option(SOCUTE_SANITIZE_UNDEFINED "Compile with undefined sanitizer support" OFF)

include(CMakeParseArguments)
include(GenerateExportHeader)

# for vcs information
find_package(Git)

# Macro that creates a header with metadata information
macro(socute_generate_metadata target target_id)
    target_include_directories(${target} PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

    set(SOCUTE_BASE_NAME ${target_id})
    set(SOCUTE_TARGET_NAME ${target})
    set(SOCUTE_PROJECT_REVISION unknown)
    if(GIT_FOUND)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} describe --always
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            OUTPUT_VARIABLE SOCUTE_PROJECT_REVISION
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif()

    configure_file("${SOCUTE_CMAKE_MODULES_DIR}/cpp/version.h.in" ${target}_version.h @ONLY)
endmacro()

# Function that sets common properties to lib or exec targets
function(socute_set_properties target target_id)
    # compile flags
    target_compile_definitions(${target} PRIVATE $<$<CONFIG:Release>:NDEBUG>)
    set_target_properties(${target} PROPERTIES CXX_EXTENSIONS NO)
    target_compile_features(${target} PRIVATE cxx_std_14)
    target_link_libraries(${target} PRIVATE SoCute_CommonWarnings SoCute_Linker)

    # account for options
    target_link_libraries(${target} PRIVATE $<$<BOOL:${SOCUTE_ENABLE_LIBCXX}>:SoCute_Libcxx>)
    target_link_libraries(${target} PRIVATE $<$<BOOL:${SOCUTE_ENABLE_MANY_WARNINGS}>:SoCute_HighWarnings>)
    target_link_libraries(${target} PRIVATE $<$<BOOL:${SOCUTE_ENABLE_PROFILING}>:SoCute_Profiling>)
    target_link_libraries(${target} PRIVATE $<$<BOOL:${SOCUTE_SANITIZE_ADDRESS}>:SoCute_AddressSanitizer>)
    target_link_libraries(${target} PRIVATE $<$<BOOL:${SOCUTE_SANITIZE_THREADS}>:SoCute_ThreadSanitizer>)
    target_link_libraries(${target} PRIVATE $<$<BOOL:${SOCUTE_SANITIZE_UNDEFINED}>:SoCute_UndefinedSanitizer>)
    if (SOCUTE_ENABLE_LTO)
        set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION ON)
    endif()

    socute_generate_metadata(${target} ${target_id})
endfunction()

# Function that creates a new library, the first argument must be the target alias,
# i.e. something of the form "Namespace::LibName", which we will parse to extract
# the Namespace and LibName components, proceed to create a NamespaceLibName library
# and a Namespace::LibName alias. the Namespace will also be use for export/install.
function(socute_add_library target_alias)
    # extract namespace/name
    string(REGEX REPLACE "(.*)::.*" "\\1" target_namespace "${target_alias}")
    string(REGEX REPLACE ".*::(.*)" "\\1" target_name "${target_alias}")
    set(target ${target_namespace}${target_name})
    set(target_base_id "${target_namespace}_${target_name}")
    string(TOUPPER ${target_base_id} target_base_id)

    # create the library
    add_library(${target} ${ARGN})
    add_library(${target_alias} ALIAS ${target})

    # export header
    generate_export_header(${target}
        BASE_NAME ${target_base_id}
        EXPORT_FILE_NAME ${target}_export.h
    )
    if (NOT BUILD_SHARED_LIBS)
        target_compile_definitions(${target} PRIVATE ${target_base_id}_STATIC_DEFINE)
    endif()

    # common properties
    socute_set_properties(${target} ${target_base_id})
endfunction()

# Function that creates a new library, the first argument must be the target alias,
# i.e. something of the form "Namespace::LibName", which we will parse to extract
# the Namespace and LibName components, proceed to create a NamespaceLibName library
# and a Namespace::LibName alias. the Namespace will also be use for export/install.
function(socute_add_executable target)
    string(TOUPPER ${target} target_base_id)

    # create the executable
    add_executable(${target} ${ARGN})

    # common properties
    socute_set_properties(${target} ${target_base_id})
endfunction()
