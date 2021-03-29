#       Copyright Pierre-Antoine LACAZE 2018 - 2020.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

# This module defines wrapper macros that supplement CMake macros with additional
# features that simplifies the creation of fully comfigured targets.
#
# Diverses CMake options are defined here and can be used project-wide to alter
# the behaviour of those macros.
include_guard()
include(GNUInstallDirs)
include(CMakeParseArguments)
include(GenerateExportHeader)
include(GateauHelpers)
include(GateauInstallProject)

# Macro that generates a header with version information
function(_gateau_generate_version_header target out)
    # for vcs information
    if (NOT Git_FOUND)
        find_package(Git QUIET)
    endif()

    gateau_target_identifier_name(${target} GATEAU_BASE_NAME)
    set(GATEAU_TARGET_NAME ${target})
    set(GATEAU_PROJECT_REVISION unknown)
    if (Git_FOUND)
        execute_process(
            COMMAND "${GIT_EXECUTABLE}" describe --always
            WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
            OUTPUT_VARIABLE GATEAU_PROJECT_REVISION
            ERROR_QUIET
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
    endif()

    gateau_get(TEMPLATES_DIR templates)
    gateau_generated_header_path(${target} "version" header_out)
    configure_file("${templates}/version.h.in" "${header_out}" @ONLY)
    set(${out} "${header_out}" PARENT_SCOPE)
endfunction()

# Macro that generates an export header
function(_gateau_generate_export_header target out)
    gateau_target_identifier_name(${target} target_id)
    gateau_generated_header_path(${target} "export" header_out)
    generate_export_header(${target}
        BASE_NAME ${target_id}
        EXPORT_FILE_NAME "${header_out}"
    )
    set(${out} "${header_out}" PARENT_SCOPE)
endfunction()

# mark headers as installable
function(_gateau_install_headers target includedir)
    # We must handle headers originating from both the source and build dirs
    get_filename_component(real_source "${PROJECT_SOURCE_DIR}" REALPATH)
    get_filename_component(real_binary "${PROJECT_BINARY_DIR}" REALPATH)
    gateau_get(RELATIVE_HEADERS_DIRS relative_dirs)

    # Installation instructions for each header
    foreach(header ${ARGN})
        # we make sure to use absolute paths
        get_filename_component(ah "${header}" REALPATH)

        # find out the base directory to derive the relative install path
        unset(base_dir)
        unset(dirs)

        # build a list of possible base_dirs
        foreach(rel_dir ${relative_dirs})
            list(APPEND dirs "${real_source}/${rel_dir}" "${real_binary}/${rel_dir}")
        endforeach()
        # also allow the project root directory as last resort
        list(APPEND dirs "${real_source}" "${real_binary}")

        foreach(dir ${dirs})
            if (ah MATCHES "^${dir}")
                set(base_dir "${dir}")
                break()
            endif()
        endforeach()

        if (base_dir)
            get_filename_component(relpath "${ah}" DIRECTORY)
            file(RELATIVE_PATH relpath "${base_dir}" "${relpath}")
            install(
                FILES "${header}"
                DESTINATION "${includedir}/${relpath}"
                COMPONENT ${target}
            )
        endif()
    endforeach()
endfunction()

# Extend an existing target with additional build parameters
# Those will be applied only if the CONDITION evaluates to true
function(gateau_extend_target target)
    set(bool_options
        AUTOMOC
        AUTOUIC
        AUTORCC
        EXCLUDE_FROM_ALL
        NO_INSTALL_HEADERS
    )
    set(mono_options
        INSTALL_INCLUDEDIR
    )
    set(multi_options
        CONDITION            # condition to respect
        SOURCES              # target_sources can be public, private or interface, not installed
        HEADERS              # target_sources PUBLIC/INTERFACE, depending on library type installed
        COMPILE_DEFINITIONS  # target_compile_definitions
        COMPILE_FEATURES     # target_compile_features
        COMPILE_OPTIONS      # target_compile_options
        INCLUDE_DIRECTORIES  # target_include_directories
        LINK_DIRECTORIES     # target_link_directories
        LINK_OPTIONS         # target_link_options
        LINK_LIBRARIES       # target_link_libraries
        PROPERTIES           # set_target_properties
        TRANSLATIONS
    )

    cmake_parse_arguments(_A "${bool_options}" "${mono_options}" "${multi_options}" ${ARGN})

    if (${_A_UNPARSED_ARGUMENTS})
        message(FATAL_ERROR "gateau_extend_target had unparsed arguments: ${_A_UNPARSED_ARGUMENTS}")
    endif()

    # test conditions
    if (NOT _A_CONDITION)
        set(_A_CONDITION ON)
    endif()
    if (NOT ${_A_CONDITION})
        return()
    endif()

    get_target_property(_type ${target} TYPE)

    # We default to PRIVATE for elements whose visibility is not explicitly set,
    # at the exception of headers, which are assumed to default to public.
    # Use INTERFACE for interface libraries, when visibility is public or unset.
    set(UNPARSED_VISIBILITY PRIVATE)
    set(PUB PUBLIC)
    set(PRI PRIVATE)
    set(is_iface FALSE)
    if (_type STREQUAL INTERFACE_LIBRARY)
        set(is_iface TRUE)
        set(UNPARSED_VISIBILITY INTERFACE)
        set(PUB INTERFACE)
        set(PRI INTERFACE)
    endif()

    cmake_parse_arguments(_S "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_SOURCES})
    cmake_parse_arguments(_H "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_HEADERS})

    if (NOT is_iface)
        target_sources(${target}
            ${PRI} ${_S_PRIVATE} ${_H_PRIVATE} ${_A_RESOURCE}
            ${PUB} ${_S_PUBLIC} ${_H_PUBLIC}
            INTERFACE ${_S_INTERFACE} ${_H_INTERFACE}
            ${UNPARSED_VISIBILITY} ${_S_UNPARSED_ARGUMENTS} ${_H_UNPARSED_ARGUMENTS}
        )
    endif()

    cmake_parse_arguments(_O "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_COMPILE_DEFINITIONS})
    target_compile_definitions(${target}
        ${PRI} ${_O_PRIVATE}
        ${PUB} ${_O_PUBLIC}
        INTERFACE ${_O_INTERFACE}
        ${UNPARSED_VISIBILITY} ${_O_UNPARSED_ARGUMENTS}
    )

    cmake_parse_arguments(_O "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_COMPILE_FEATURES})
    target_compile_features(${target}
        ${PRI} ${_O_PRIVATE}
        ${PUB} ${_O_PUBLIC}
        INTERFACE ${_O_INTERFACE}
        ${UNPARSED_VISIBILITY} ${_O_UNPARSED_ARGUMENTS}
    )

    cmake_parse_arguments(_O "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_COMPILE_OPTIONS})
    target_compile_options(${target}
        ${PRI} ${_O_PRIVATE}
        ${PUB} ${_O_PUBLIC}
        INTERFACE ${_O_INTERFACE}
        ${UNPARSED_VISIBILITY} ${_O_UNPARSED_ARGUMENTS}
    )

    cmake_parse_arguments(_O "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_INCLUDE_DIRECTORIES})
    target_include_directories(${target}
        ${PRI} ${_O_PRIVATE}
        ${PUB} ${_O_PUBLIC}
        INTERFACE ${_O_INTERFACE}
        ${UNPARSED_VISIBILITY} ${_O_UNPARSED_ARGUMENTS}
    )

    cmake_parse_arguments(_O "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_LINK_DIRECTORIES})
    target_link_directories(${target}
        ${PRI} ${_O_PRIVATE}
        ${PUB} ${_O_PUBLIC}
        INTERFACE ${_O_INTERFACE}
        ${UNPARSED_VISIBILITY} ${_O_UNPARSED_ARGUMENTS}
    )

    cmake_parse_arguments(_O "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_LINK_OPTIONS})
    target_link_options(${target}
        ${PRI} ${_O_PRIVATE}
        ${PUB} ${_O_PUBLIC}
        INTERFACE ${_O_INTERFACE}
        ${UNPARSED_VISIBILITY} ${_O_UNPARSED_ARGUMENTS}
    )

    cmake_parse_arguments(_O "" "" "PUBLIC;PRIVATE;INTERFACE" ${_A_LINK_LIBRARIES})
    target_link_libraries(${target}
        ${PRI} ${_O_PRIVATE}
        ${PUB} ${_O_PUBLIC}
        INTERFACE ${_O_INTERFACE}
        ${UNPARSED_VISIBILITY} ${_O_UNPARSED_ARGUMENTS}
    )

    if (_A_PROPERTIES)
        set_target_properties(${target} PROPERTIES ${_A_PROPERTIES})
    endif()

    foreach(opt ${bool_options})
        if (_A_${opt})
            set_target_properties(${target} PROPERTIES ${opt} ON)
        endif()
    endforeach()

    # Installation of headers
    if (NOT _A_NO_INSTALL_HEADERS)
        get_target_property(_A_NO_INSTALL_HEADERS ${target} no_install_headers)
    endif()
    if (NOT _A_NO_INSTALL_HEADERS)
        if (NOT _A_INSTALL_INCLUDEDIR)
            get_target_property(_A_INSTALL_INCLUDEDIR ${target} includedir)
        endif()
        if (NOT _A_INSTALL_INCLUDEDIR)
            set(_A_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}")
        endif()

        _gateau_install_headers(${target}
            "${_A_INSTALL_INCLUDEDIR}"
            ${_H_INTERFACE} ${_H_PRIVATE} ${_H_PUBLIC} ${_H_UNPARSED_ARGUMENTS}
        )
    endif()

    # Nice organization of sources
    if (is_iface)
        get_target_property(sources ${target} INTERFACE_SOURCES)
    else()
        get_target_property(sources ${target} SOURCES)
    endif()
    source_group("" FILES ${sources})

    if (_A_RESOURCES)
        get_target_property(resource ${target} RESOURCE)
        if (NOT resource)
            set(resource ${_A_RESOURCES})
        else()
            list(APPEND resource ${_A_RESOURCES})
        endif()
        set_target_properties(${target} PROPERTIES RESOURCE "${resource}")
    endif()

    # TODO translations
endfunction()

# Set common configuration parameters on the target
function(_gateau_configure_target target no_version_header)
    # mark the target as known
    gateau_append(KNOWN_TARGETS ${target})

    get_cmake_property(languages ENABLED_LANGUAGES)

    # extend the target with appropriate defaults
    if (C IN_LIST languages)
        gateau_get(C_STANDARD cstd)
    endif()
    if (CXX IN_LIST languages)
        gateau_get(CXX_STANDARD cxxstd)
    endif()

    # find include directories to append
    gateau_get(RELATIVE_HEADERS_DIRS relative_dirs)
    set(build_dirs)
    foreach(rel_dir ${relative_dirs})
        set(_sdir "${PROJECT_SOURCE_DIR}/${rel_dir}")
        set(_bdir "${PROJECT_BINARY_DIR}/${rel_dir}")
        if (IS_DIRECTORY "${_sdir}")
            list(APPEND build_dirs
                $<BUILD_INTERFACE:${_sdir}>
                $<BUILD_INTERFACE:${_bdir}>
            )
        endif()
    endforeach()
    if (NOT build_dirs)
        list(APPEND build_dirs
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
            $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
        )
    endif()

    gateau_extend_target(${target}
        INCLUDE_DIRECTORIES
            PUBLIC
                ${build_dirs}
                $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
                $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
                $<INSTALL_INTERFACE:include>
        PROPERTIES
            EXPORT_NAME ${target}
        COMPILE_FEATURES
            PUBLIC
                ${cstd}
                ${cxxstd}
    )

    # add a version header
    if (NOT no_version_header)
        _gateau_generate_version_header(${target} version_header)
        gateau_extend_target(${target} HEADERS "${version_header}")
    endif()

    set(ident ${${PROJECT_NAME}_IDENT})
    get_target_property(_type ${target} TYPE)
    if (NOT _type STREQUAL INTERFACE_LIBRARY)
        # output directory
        gateau_extend_target(${target}
            CONDITION
                ${ident}_OUTPUT_DIRECTORY
            PROPERTIES
                ARCHIVE_OUTPUT_DIRECTORY "${${ident}_OUTPUT_DIRECTORY}"
                LIBRARY_OUTPUT_DIRECTORY "${${ident}_OUTPUT_DIRECTORY}"
                RUNTIME_OUTPUT_DIRECTORY "${${ident}_OUTPUT_DIRECTORY}"
        )

        gateau_get(NAME_PREFIX name_prefix)
        gateau_get(LIBRARY_NAME_PREFIX lib_name_prefix)
        gateau_get(RUNTIME_NAME_PREFIX exe_name_prefix)

        if (NOT lib_name_prefix)
            set(lib_name_prefix "${name_prefix}")
        endif()
        if (NOT exe_name_prefix)
            set(exe_name_prefix "${name_prefix}")
        endif()

        # Compiler options
        gateau_extend_target(${target}
            LINK_LIBRARIES
                $<$<BOOL:${${ident}_ENABLE_COMMON_WARNINGS}>:Gateau_CommonWarnings>
                $<$<BOOL:${${ident}_KEEP_TEMPS}>:Gateau_SaveTemps>
                $<$<BOOL:${${ident}_ENABLE_LIBCXX}>:Gateau_Libcxx>
                $<$<BOOL:${${ident}_ENABLE_MANY_WARNINGS}>:Gateau_HighWarnings>
                $<$<BOOL:${${ident}_ENABLE_WERROR}>:Gateau_Werror>
                $<$<BOOL:${${ident}_ENABLE_PROFILING}>:Gateau_Profiling>
                $<$<BOOL:${${ident}_KEEP_TEMPS}>:Gateau_SaveTemps>
                $<$<BOOL:${${ident}_SPLIT_DEBUG_INFO}>:Gateau_SplitDebugInfo>
                $<$<BOOL:${${ident}_SANITIZE_ADDRESS}>:Gateau_AddressSanitizer>
                $<$<BOOL:${${ident}_SANITIZE_THREADS}>:Gateau_ThreadSanitizer>
                $<$<BOOL:${${ident}_SANITIZE_UNDEFINED}>:Gateau_UndefinedSanitizer>
                $<$<BOOL:${${ident}_ENABLE_AUTOSELECT_LINKER}>:Gateau_Linker>
            COMPILE_OPTIONS
                $<$<CONFIG:Release>:-march=native>
            PROPERTIES
                $<$<CONFIG:Release>:C_VISIBILITY_PRESET hidden>
                $<$<CONFIG:Release>:CXX_VISIBILITY_PRESET hidden>
                $<$<CONFIG:Release>:VISIBILITY_INLINES_HIDDEN 1>
                LIBRARY_OUTPUT_NAME ${lib_name_prefix}${target}
                ARCHIVE_OUTPUT_NAME ${lib_name_prefix}${target}
                RUNTIME_OUTPUT_NAME ${exe_name_prefix}${target}
                BUILD_RPATH_USE_ORIGIN ON
                INSTALL_RPATH_USE_LINK_PATH TRUE
                INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}:$ORIGIN"
        )

        # CCache
        if (${ident}_USE_CCACHE)
            find_program(CCACHE_PROGRAM ccache)
            gateau_extend_target(${target}
                CONDITION
                    CCACHE_PROGRAM
                PROPERTIES
                    C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}"
                    CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}"
            )
        endif()

        # LTO
        gateau_extend_target(${target}
            CONDITION
                ${ident}_ENABLE_LTO
            LINK_OPTIONS
                -flto
            PROPERTIES
                INTERPROCEDURAL_OPTIMIZATION ON
        )
    endif()
endfunction()

# Function that creates a new library
# gateau_add_library(
#     <name>
#     [STATIC | SHARED | OBJECT | MODULE | INTERFACE]
#     [NO_INSTALL] [NO_INSTALL_HEADERS]
#     [NO_EXPORT]
#     [INSTALL_LIBDIR <dir>]
#     [INSTALL_INCLUDEDIR <dir>]
#     [other options accepted by gateau_extend_target()]...
# )
#
# The following options are accepted
# - one of STATIC SHARED OBJECT MODULE INTERFACE (defaults to SHARED): library type
# - NO_INSTALL: do not install this target
# - NO_INSTALL_HEADER: do not install the dev headers
# - NO_EXPORT: the target is not exported to the cmake package module installed
# - INSTALL_LIBDIR: override the libraries installation directory path
# - INSTALL_INCLUDEDIR: override the headers installation directory path
function(gateau_add_library lib)
    set(bool_options
        STATIC SHARED OBJECT MODULE INTERFACE  # add_library
        NO_EXPORT           # Do not export this target in the cmake package module
        NO_INSTALL          # Do not install this target
        NO_INSTALL_HEADERS  # Do not install development headers
        NO_EXPORT_HEADER    # Do not generate an export header
        NO_VERSION_HEADER   # DO not generate a version header
    )
    set(mono_options OUTPUT_NAME INSTALL_BINDIR INSTALL_LIBDIR INSTALL_INCLUDEDIR)
    cmake_parse_arguments(SAL "${bool_options}" "${mono_options}" "" ${ARGN})

    # ensure a proper install prefix is none was given
    gateau_setup_install_prefix()

    set(_type SHARED)
    if (SAL_STATIC)
        set(_type STATIC)
    endif()
    if (SAL_OBJECT)
        set(_type OBJECT)
    endif()
    if (SAL_MODULE)
        set(_type MODULE)
    endif()
    if (SAL_INTERFACE)
        set(_type INTERFACE)
    endif()

    if (SAL_NO_INSTALL)
        set (SAL_NO_EXPORT TRUE)
    endif()
    if (NOT SAL_INSTALL_BINDIR)
        set(SAL_INSTALL_BINDIR "${CMAKE_INSTALL_BINDIR}")
    endif()
    if (NOT SAL_INSTALL_LIBDIR)
        set(SAL_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}")
    endif()
    if (NOT SAL_INSTALL_INCLUDEDIR)
        set(SAL_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}")
    endif()

    gateau_target_alias_name(${lib} alias)

    # create the library
    add_library(${lib} ${_type})
    add_library(${alias} ALIAS ${lib})

    # record installation needs and destination for later calls to extend_target
    set(no_headers FALSE)
    if (SAL_NO_INSTALL OR SAL_NO_INSTALL_HEADERS)
        set(no_headers TRUE)
    endif()

    # (lowercase properties are always authorized)
    set_target_properties(${lib} PROPERTIES
        no_install ${SAL_NO_INSTALL}
        no_install_headers ${no_headers}
        no_export ${SAL_NO_EXPORT}
        includedir "${SAL_INSTALL_INCLUDEDIR}"
    )

    # configure the target with good defaults
    _gateau_configure_target(${lib} ${SAL_NO_VERSION_HEADER})

    if (SAL_OUTPUT_NAME)
        gateau_extend_target(${lib}
            PROPERTIES
                LIBRARY_OUTPUT_NAME "${SAL_OUTPUT_NAME}"
                ARCHIVE_OUTPUT_NAME "${SAL_OUTPUT_NAME}"
        )
    endif()

    if (NOT SAL_INTERFACE AND NOT SAL_NO_EXPORT_HEADER)
        # Export header
        _gateau_generate_export_header(${lib} export_header)
        gateau_extend_target(${lib}
            HEADERS "${export_header}"
            PROPERTIES VERSION ${PROJECT_VERSION}
        )
    endif()

    # add passed options last, as some may override some of our defaults
    gateau_extend_target(${lib} ${SAL_UNPARSED_ARGUMENTS})

    # Installation
    if (NOT SAL_NO_INSTALL)
        if (NOT SAL_NO_EXPORT)
            set(export_option EXPORT "${PROJECT_NAME}Targets")
        endif()

        # mark the target as installable
        if (SAL_SHARED)
            set(namelink_option NAMELINK_SKIP)
        endif()

        install(
            TARGETS ${lib}
            ${export_option}
            RUNTIME
                DESTINATION "${SAL_INSTALL_BINDIR}"
                COMPONENT ${PROJECT_NAME}_runtime
            LIBRARY
                DESTINATION "${SAL_INSTALL_LIBDIR}"
                COMPONENT ${PROJECT_NAME}_runtime
                NAMELINK_COMPONENT ${PROJECT_NAME}_devel
                ${namelink_option}
            ARCHIVE
                DESTINATION "${SAL_INSTALL_LIBDIR}"
                COMPONENT ${PROJECT_NAME}_devel
            INCLUDES
                DESTINATION "${SAL_INSTALL_INCLUDEDIR}"
            RESOURCE
                DESTINATION "${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}"
                EXCLUDE_FROM_ALL
        )
    endif()

    # TODO handle translations for this target
endfunction()

# Add a plugin, a library declared as a module in cmake parlance
function(gateau_add_plugin lib)
    gateau_add_library("${lib}" MODULE ${ARGN})
endfunction()

# Function that creates a new executable and configures reasonable defaults as
# well as installation instructions
function(gateau_add_executable exe)
    set(bool_options
        NO_INSTALL          # Do not install this target
        NO_EXPORT           # Do not export this target
        VERSION_HEADER      # Do generate a version header
    )
    set(mono_options OUTPUT_NAME INSTALL_BINDIR)
    cmake_parse_arguments(SAE "${bool_options}" "${mono_options}" "" ${ARGN})

    # ensure a proper install prefix is none was given
    gateau_setup_install_prefix()

    if (NOT SAE_INSTALL_BINDIR)
        set(SAE_INSTALL_BINDIR "${CMAKE_INSTALL_BINDIR}")
    endif()
    if (NOT SAE_OUTPUT_NAME)
        set(SAE_OUTPUT_NAME ${exe})
    endif()
    if (SAE_NO_INSTALL)
        set (SAE_NO_EXPORT TRUE)
    endif()

    # create the executable
    add_executable(${exe})

    # mark installable status
    set_target_properties(${exe} PROPERTIES
        no_install ${SAE_NO_INSTALL}
        no_export ${SAE_NO_EXPORT}
        no_install_headers TRUE
    )

    set(_no_version_header TRUE)
    if (SAE_VERSION_HEADER)
        set(_no_version_header FALSE)
    endif()

    # configure the target with good defaults
    _gateau_configure_target(${exe} ${_no_version_header})

    # extend the target with appropriate defaults
    gateau_extend_target(${exe}
        PROPERTIES
            RUNTIME_OUTPUT_NAME "${SAE_OUTPUT_NAME}"
    )

    # add passed options last, as some may override some of our defaults
    gateau_extend_target(${exe} ${SAE_UNPARSED_ARGUMENTS})

    # Installation instructions for the target
    if (NOT SAE_NO_INSTALL)
        if (NOT SAE_NO_EXPORT)
            set(export_option EXPORT "${PROJECT_NAME}Targets")
        endif()

        install(
            TARGETS ${exe}
            ${export_option}
            RUNTIME
                DESTINATION "${SAL_INSTALL_BINDIR}"
                COMPONENT ${PROJECT_NAME}_Runtime
        )
    endif()

    # TODO handle translations for this target
endfunction()
