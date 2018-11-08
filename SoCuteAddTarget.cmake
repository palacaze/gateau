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

include(CMakeParseArguments)
include(GenerateExportHeader)
include(SoCuteHelpers)

# for vcs information
find_package(Git)

# Macro that creates a header with metadata information
macro(socute_generate_metadata alias target target_id)
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

    configure_file("${SOCUTE_CMAKE_MODULES_DIR}/templates/version.h.in"
                   "${alias}Version.h" @ONLY)
endmacro()

# Function that sets common properties to lib or exec targets
function(socute_set_properties alias target target_id)
    # compile flags
    target_compile_definitions(${target} PRIVATE $<$<CONFIG:Release>:NDEBUG>)
    set_target_properties(${target} PROPERTIES CXX_EXTENSIONS NO)
    target_compile_features(${target} PRIVATE cxx_std_14)

    # account for options
    target_link_libraries(${target} PRIVATE
        $<$<BOOL:${SOCUTE_ENABLE_COMMON_WARNINGS}>:SoCute_CommonWarnings>
        $<$<BOOL:${SOCUTE_ENABLE_AUTOSELECT_LINKER}>:SoCute_Linker>
        $<$<BOOL:${SOCUTE_ENABLE_LIBCXX}>:SoCute_Libcxx>
        $<$<BOOL:${SOCUTE_ENABLE_MANY_WARNINGS}>:SoCute_HighWarnings>
        $<$<BOOL:${SOCUTE_ENABLE_PROFILING}>:SoCute_Profiling>
        $<$<BOOL:${SOCUTE_SANITIZE_ADDRESS}>:SoCute_AddressSanitizer>
        $<$<BOOL:${SOCUTE_SANITIZE_THREADS}>:SoCute_ThreadSanitizer>
        $<$<BOOL:${SOCUTE_SANITIZE_UNDEFINED}>:SoCute_UndefinedSanitizer>
    )
    if (SOCUTE_ENABLE_LTO)
        set_target_properties(${target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION ON)
    endif()

    # default to hidden to catch symbol export problems
    set_target_properties(${target} PROPERTIES
        $<$<CONFIG:Release>:CXX_VISIBILITY_PRESET hidden>
        $<$<CONFIG:Release>:VISIBILITY_INLINES_HIDDEN 1>
    )

    socute_generate_metadata(${alias} ${target} ${target_id})
endfunction()

# create the prefix string that will be used to namespace C macros in generated headers
function(socute_target_id_prefix alias out)
    # Big hack, the SoCute namespace used to prefix our projects contains a
    # mid-word capital letter, but SO_CUTE_PROJECT_LIB would be very ugly compared
    # to SOCUTE_PROJECT_LIB, so we actually special case for this.
    set(namespace ${PROJECT_NAME})
    string(REPLACE "SoCute" "Socute" namespace ${namespace})
    set(id "${namespace}${alias}")

    socute_to_identifier(${id} id)
    set(${out} ${id} PARENT_SCOPE)
endfunction()

# Function that creates a new library, the first argument must be the target alias,
# i.e. something of the form "Namespace::LibName", which we will parse to extract
# the Namespace and LibName components, proceed to create a NamespaceLibName library
# and a Namespace::LibName alias. the Namespace will also be use for export/install.
function(socute_add_library lib)
    set(namespace ${PROJECT_NAME})
    set(target ${namespace}${lib})
    set(target_alias ${namespace}::${lib})
    socute_target_id_prefix(${lib} target_base_id)

    # create the library
    add_library(${target} ${ARGN})
    add_library(${target_alias} ALIAS ${target})

    # ensure a proper version and short name
    set_target_properties(${target} PROPERTIES
        VERSION ${PROJECT_VERSION}
        EXPORT_NAME ${lib}
    )

    # export header
    generate_export_header(${target}
        BASE_NAME ${target_base_id}
        EXPORT_FILE_NAME ${lib}Export.h
    )
    if (NOT BUILD_SHARED_LIBS)
        target_compile_definitions(${target} PRIVATE ${target_base_id}_STATIC_DEFINE)
    endif()

    # common properties
    socute_set_properties(${lib} ${target} ${target_base_id})
endfunction()

# Function that creates a new library, the first argument must be the target alias,
# i.e. something of the form "Namespace::LibName", which we will parse to extract
# the Namespace and LibName components, proceed to create a NamespaceLibName library
# and a Namespace::LibName alias. the Namespace will also be use for export/install.
function(socute_add_executable exe)
    set(namespace ${PROJECT_NAME})
    set(target ${namespace}${exe})
    set(target_alias ${namespace}::${exe})
    socute_target_id_prefix(${exe} target_base_id)

    # create the executable
    add_executable(${target} ${ARGN})

    set_target_properties(${target} PROPERTIES
        VERSION ${PROJECT_VERSION}
        EXPORT_NAME ${exe}
    )

    # common properties
    socute_set_properties(${exe} ${target} ${target_base_id})
endfunction()
