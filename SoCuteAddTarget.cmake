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

# for vcs information
find_package(Git)

# Macro that creates a header with metadata information
macro(socute_generate_metadata alias target target_id)
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

    socute_generated_dir(gendir)
    configure_file("${SOCUTE_CMAKE_MODULES_DIR}/templates/version.h.in"
                   "${gendir}/${alias}Version.h" @ONLY)
endmacro()

# Function that sets common properties to lib or exec targets
function(socute_set_properties alias target target_id)
    # compile flags
    target_compile_definitions(${target} PRIVATE $<$<CONFIG:Release>:NDEBUG>)
    set_target_properties(${target} PROPERTIES CXX_EXTENSIONS NO)
    target_compile_features(${target} PRIVATE cxx_std_14)

    # add the src dir to the include directories
    target_include_directories(${target} PUBLIC
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/src>
        $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/src>
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
        $<$<CONFIG:Release>:CXX_VISIBILITY_PRESET hidden>
        $<$<CONFIG:Release>:VISIBILITY_INLINES_HIDDEN 1>
    )

    socute_generate_metadata(${alias} ${target} ${target_id})
endfunction()

# Function that creates a new library, the first argument must be either an module
# name for multi libraries projects, or exactly the package name if there is only
# one library to be built. That way for multi libraries, the library will be
# called OrgaPackageMod and aliased to Orga::PackageMod, and for single library
# projects it will be called OrgaPackage and aliasd to Orga::Package
function(socute_add_library lib)
    socute_target_full_name(${lib} target)
    socute_target_short_name(${lib} export_name)
    socute_target_alias_name(${lib} target_alias)
    socute_target_id_prefix(${lib} target_base_id)

    # create the library
    add_library(${target} ${ARGN})
    add_library(${target_alias} ALIAS ${target})

    # record the list of libraries in a property
    set_property(GLOBAL APPEND PROPERTY SOCUTE_LIBRARY_LIST ${lib})

    # ensure a proper version and short name
    set_target_properties(${target} PROPERTIES
        VERSION ${PROJECT_VERSION}
        EXPORT_NAME ${export_name}
    )

    # export header
    socute_generated_dir(gendir)
    generate_export_header(${target}
        BASE_NAME ${target_base_id}
        EXPORT_FILE_NAME ${gendir}/${lib}Export.h
    )
    if (NOT BUILD_SHARED_LIBS)
        target_compile_definitions(${target} PRIVATE ${target_base_id}_STATIC_DEFINE)
    endif()

    # common properties
    socute_set_properties(${lib} ${target} ${target_base_id})
endfunction()

# Function that creates a new library, the first argument must the name short
# executalbe name, which will be appended to the package name to form the full
# target name.
function(socute_add_executable exe)
    socute_target_full_name(${exe} target)
    socute_target_alias_name(${exe} target_alias)
    socute_target_id_prefix(${exe} target_base_id)

    # create the executable
    add_executable(${target} ${ARGN})

    set_target_properties(${target} PROPERTIES
        EXPORT_NAME ${exe}
    )

    # common properties
    socute_set_properties(${exe} ${target} ${target_base_id})
endfunction()
