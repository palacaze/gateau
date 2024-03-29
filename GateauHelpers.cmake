#       Copyright Pierre-Antoine LACAZE 2018 - 2020.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

include_guard()

# Dump variables bound to current directory on stdout
function(gateau_dump_variables)
    get_cmake_property(_variables VARIABLES)
    list(SORT _variables)
    foreach (_var ${_variables})
        if (ARGV0)
            unset(MATCHED)
            string(REGEX MATCH ${ARGV0} MATCHED ${_var})
            if (NOT MATCHED)
                continue()
            endif()
        endif()
        message(STATUS ">>> ${_var} = ${${_var}}")
    endforeach()
endfunction()

# full name of a namespaced variable for the current project
function(_gateau_var_name name out)
    set(${out} ${${PROJECT_NAME}_IDENT}_${name} PARENT_SCOPE)
endfunction()

# Try to get the value of a variable that may or may not be defined, or fallback
# to a default value.
# The order is:
# 1) ${project_ident}_${name}
# 2) ENV{${project_ident}_${name}}
# 3) GATEAU_${name}
# 4) ENV{GATEAU_${name}}
# 5) fallback
function(gateau_get_or name fallback out)
    set(ident ${${PROJECT_NAME}_IDENT})

    # It makes sense to ckeck variables of the parent project at first init
    set(is_master TRUE)
    if (NOT CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
        set(parent_ident ${${PROJECT_NAME}_IDENT})
        set(is_master FALSE)
    endif()

    unset(var)
    if (DEFINED ${ident}_${name})
        set(var "${${ident}_${name}}")
    elseif (DEFINED ENV{${ident}_${name}})
        set(var "$ENV{${ident}_${name}}")
    elseif (NOT is_master AND DEFINED ${parent_ident}_${name})
        set(var "${${parent_ident}_${name}}")
    elseif (NOT is_master AND DEFINED ENV{${parent_ident}_${name}})
        set(var "$ENV{${parent_ident}_${name}}")
    elseif (DEFINED GATEAU_${name})
        set(var "${GATEAU_${name}}")
    elseif (DEFINED ENV{GATEAU_${name}})
        set(var "$ENV{GATEAU_${name}}")
    endif()

    # if the variable is empty or undefined, set to fallback
    if (NOT DEFINED var OR "${var}" STREQUAL "")
        set(var "${fallback}")
    endif()
    set(${out} "${var}" PARENT_SCOPE)
endfunction()

# Declare a cache variable and ensure proper default value
# If a variable or ENV variable of the same name exists, its value will be used
# instead of the default value.
function(gateau_declare_var name default doc type)
    gateau_get_or(${name} "${default}" def)
    _gateau_var_name(${name} ident)
    set(${ident} "${def}" CACHE ${type} "${doc}")
endfunction()

# Declare a new option and ensure proper default value
# Just a shorthand for declare_var(... BOOL)
function(gateau_declare_option name default doc)
    gateau_declare_var(${name} "${default}" "${doc}" BOOL)
endfunction()

# Declare an internal cache variable and ensure proper default value
function(gateau_declare_internal name value)
    _gateau_var_name(${name} ident)
    set(${ident} "${value}" CACHE INTERNAL "")
endfunction()

# Get a project cache variable value
function(gateau_get name value_out)
    _gateau_var_name(${name} ident)
    set(${value_out} "${${ident}}" PARENT_SCOPE)
endfunction()

# Set a project cache variable value
function(gateau_set name value)
    # use set_property to keep the other properties on this cache value
    _gateau_var_name(${name} ident)
    set_property(CACHE ${ident} PROPERTY VALUE "${value}")
endfunction()

# Append a value to a CACHE variable of list/string type
function(gateau_append name str)
    _gateau_var_name(${name} ident)
    if (NOT DEFINED ${ident})
        gateau_declare_var(${name} "${str}" "" INTERNAL)
    else()
        gateau_get(${name} vals)
        if (NOT "${str}" IN_LIST vals)
            list(APPEND vals "${str}")
            gateau_set(${name} "${vals}")
        endif()
    endif()
endfunction()

# Prepend a value to a CACHE variable of list/string type
function(gateau_prepend name str)
    _gateau_var_name(${name} ident)
    if (NOT DEFINED ${ident})
        gateau_declare_var(${name} "${str}" "" INTERNAL)
    else()
        gateau_get(${name} vals)
        if (NOT "${str}" IN_LIST vals)
            list(PREPEND vals "${str}")
            gateau_set(${name} "${vals}")
        endif()
    endif()
endfunction()

# Build the camelcase name for a string
function(gateau_to_camelcase var out)
    string(REGEX REPLACE "([^a-z0-9])" "_\\1" txt "${var}")
    string(TOLOWER "${txt}" txt)
    if (${txt} MATCHES "^_")
        string(SUBSTRING "${txt}" 1 -1 txt)
    endif()
    string(REPLACE "_" ";" txt "${txt}")
    set(res)
    foreach (w ${txt})
        if (w)
            string(SUBSTRING ${w} 0 1 l)
            string(TOUPPER ${l} l)
            string(APPEND res ${l})
            string(SUBSTRING ${w} 1 -1 l)
            string(APPEND res ${l})
        endif()
    endforeach()
    set(${out} "${res}" PARENT_SCOPE)
endfunction()

# Build the snakecase name for a string
# Precondition: the input string is CamelCase
function(gateau_to_snakecase var out)
    string(REPLACE " " "_" txt "${var}")
    string(REGEX REPLACE "([A-Z])" "_\\1" txt "${txt}")
    string(TOLOWER "${txt}" txt)
    if (${txt} MATCHES "^_")
        string(SUBSTRING "${txt}" 1 -1 txt)
    endif()
    string(MAKE_C_IDENTIFIER "${txt}" txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build the hyphenated name for a string
# Precondition: the input string is CamelCase
function(gateau_to_hyphenated var out)
    gateau_to_snakecase(${var} txt)
    string(REPLACE "_" "-" txt "${txt}")
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build a C identifier out of variable
function(gateau_to_identifier var out)
    gateau_to_snakecase(${var} txt)
    string(TOUPPER "${txt}" txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Find out the generated header path for the given target and suffix
function(gateau_generated_header_path target suffix header_out)
    gateau_get(GENERATED_HEADER_CASE case)
    if (case STREQUAL HYPHEN)
        gateau_to_hyphenated("${target}-${suffix}" name)
    elseif (case STREQUAL SNAKE)
        gateau_to_snakecase("${target}_${suffix}" name)
    else()
        gateau_to_camelcase("${target}" camel_target)
        gateau_to_camelcase("${suffix}" camel_suffix)
        set(name "${camel_target}${camel_suffix}")
    endif()

    gateau_get(GENERATED_HEADER_EXT ext)
    set(header_out "${CMAKE_CURRENT_BINARY_DIR}/${name}.${ext}" PARENT_SCOPE)
endfunction()

# Build the export name of a target
function(gateau_target_export_name target out)
    set(${out} "${target}" PARENT_SCOPE)
endfunction()

# Build the fullname of a short module name
function(gateau_target_full_name target out)
    set(${out} "${PROJECT_NAME}${target}" PARENT_SCOPE)
endfunction()

# Build the alias name of a short module name
function(gateau_target_alias_name target out)
    gateau_get(NAMESPACE nspace)
    set(${out} "${nspace}::${target}" PARENT_SCOPE)
endfunction()

# Build the filename corresponding to a target
function(gateau_target_file_name target out)
    gateau_to_snakecase(${target} snake_target)
    gateau_to_snakecase("${PROJECT_NAME}" txt)
    set(${out} "${txt}_${snake_target}" PARENT_SCOPE)
endfunction()

# Build the prefix to namespace C macros in generated headers for a given target
function(gateau_target_identifier_name target out)
    gateau_to_identifier(${target} id_target)
    gateau_to_identifier("${PROJECT_NAME}" txt)
    set(${out} "${txt}_${id_target}" PARENT_SCOPE)
endfunction()

# cat in_file into out_file
function(gateau_concat_file in_file out_file)
    file(READ "${in_file}" _contents)
    file(APPEND "${out_file}" "${_contents}")
endfunction()

# create a directory and ensure existence
function(gateau_create_dir dir)
    file(MAKE_DIRECTORY "${dir}")
    if (NOT EXISTS "${dir}")
        message(FATAL_ERROR "could not find or make directory ${dir}")
    endif()
endfunction()

# The actual build type used to build external deps.
# for multiconfig generators, we choose an appropriate one, Release if possible
function(gateau_external_build_type build_type)
    if (GENERATOR_IS_MULTI_CONFIG)
        if (Release IN_LIST CMAKE_CONFIGURATION_TYPES)
            set(_build_type Release)
        else()
            list(GET CMAKE_CONFIGURATION_TYPES 0 _build_type)
        endif()
    else()
        gateau_get_or(EXTERNAL_BUILD_TYPE Release _build_type)
    endif()

    set(${build_type} "${_build_type}" PARENT_SCOPE)
endfunction()

# Create a config specific path that builds a subdirectory of prefix containing
# the compiler/syste$m/config triplet to ensure abi consistency.
function(_gateau_config_specific_dir prefix out_dir)
    # default build type folder name
    gateau_external_build_type(build_type)

    # System name
    string(TOLOWER "${build_type}" build_type)
    string(TOLOWER "${CMAKE_SYSTEM_NAME}" sys)
    string(TOLOWER "${CMAKE_CXX_COMPILER_ID}-${CMAKE_CXX_COMPILER_VERSION}" comp)
    gateau_get(ARCH arch)
    set(datadir "${prefix}/${sys}-${comp}-x${arch}-${build_type}")

    # Ensure we can actually use this directory
    gateau_create_dir("${datadir}")
    set(${out_dir} "${datadir}" PARENT_SCOPE)
endfunction()

# Get the root directory where all external packages will be handled.
# The fallback is ${PROJECT_BINARY_DIR}/external.
function(gateau_external_root out_dir)
    set(fallback "${PROJECT_BINARY_DIR}/external")
    gateau_get_or(EXTERNAL_ROOT "${fallback}" out)
    set(${out_dir} "${out}" PARENT_SCOPE)
endfunction()

# Get the download directory for external package archives to be saved.
# The fallback is ${gateau_external_root}/download.
function(gateau_external_download_root out_dir)
    gateau_external_root(external_root)
    set(fallback "${external_root}/download")
    gateau_get_or(DOWNLOAD_CACHE "${fallback}" out)
    set(${out_dir} "${out}" PARENT_SCOPE)
endfunction()

# The package-specific download dir
function(gateau_external_download_dir pkg out_dir)
    gateau_external_download_root(download_root)
    set(${out_dir} "${download_root}/${pkg}" PARENT_SCOPE)
endfunction()

# Where external packages source code is decompressed
function(gateau_external_source_root out_dir)
    gateau_external_root(external_root)
    set(${out_dir} "${external_root}/src" PARENT_SCOPE)
endfunction()

# The package-specific source dir
function(gateau_external_source_dir pkg out_dir)
    gateau_external_source_root(source_root)
    set(${out_dir} "${source_root}/${pkg}" PARENT_SCOPE)
endfunction()

# Where external packages source code is built
function(gateau_external_build_root out_dir)
    gateau_external_root(external_root)
    _gateau_config_specific_dir("${external_root}/build" build_root)
    set(${out_dir} "${build_root}" PARENT_SCOPE)
endfunction()

# The package-specific build dir
function(gateau_external_build_dir pkg out_dir)
    gateau_external_build_root(build_root)
    set(${out_dir} "${build_root}/${pkg}" PARENT_SCOPE)
endfunction()

# Get the install prefix directory for external package.
# The fallback is ${gateau_external_root}/prefix/${config_specific}.
function(gateau_external_install_prefix out_dir)
    gateau_external_root(external_root)
    _gateau_config_specific_dir("${external_root}/prefix" fallback)
    gateau_get_or(EXTERNAL_INSTALL_PREFIX "${fallback}" out)
    set(${out_dir} "${out}" PARENT_SCOPE)
endfunction()

function(gateau_external_install_manifest_dir out_dir)
    gateau_external_install_prefix(install_prefix)
    set(${out_dir} "${install_prefix}/share/gateau/manifests" PARENT_SCOPE)
endfunction()
