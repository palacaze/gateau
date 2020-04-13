include_guard()

# Dump variables bound to current directory on stdout
function(socute_dump_variables)
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

# Try to get the value of a variable that may or may not be defined, or fallback
# to a default value.
# The order is:
# 1) ${PROJECT_IDENT}_${name}
# 2) ENV{${PROJECT_IDENT}_${name}}
# 3) SOCUTE_${name}
# 4) ENV{SOCUTE_${name}}
# 5) fallback
function(socute_get_or name fallback out)
    unset(var)
    if (DEFINED ${PROJECT_IDENT}_${name})
        set(var "${${PROJECT_IDENT}_${name}}")
    elseif (DEFINED ENV{${PROJECT_IDENT}_${name}})
        set(var "$ENV{${PROJECT_IDENT}_${name}}")
    elseif (DEFINED SOCUTE_${name})
        set(var "${SOCUTE_${name}}")
    elseif (DEFINED ENV{SOCUTE_${name}})
        set(var "$ENV{SOCUTE_${name}}")
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
function(socute_declare_var name default doc type)
    socute_get_or(${name} "${default}" def)
    set(${PROJECT_IDENT}_${name} "${def}" CACHE ${type} "${doc}")
endfunction()

# Declare a new option and ensure proper default value
# Just a shorthand for declare_var(... BOOL)
function(socute_declare_option name default doc)
    socute_declare_var(${name} "${default}" "${doc}" BOOL)
endfunction()

# Declare an internal cache variable and ensure proper default value
function(socute_declare_internal name default)
    socute_declare_var(${name} "${default}" "" INTERNAL)
endfunction()

# Get a project cache variable value
function(socute_get name value_out)
    set(${value_out} "${${PROJECT_IDENT}_${name}}" PARENT_SCOPE)
endfunction()

# Set a project cache variable value
function(socute_set name value)
    # use set_property to keep the other properties on this cache value
    set_property(CACHE ${PROJECT_IDENT}_${name} PROPERTY VALUE "${value}")
endfunction()

# Append a value to a CACHE variable of list/string type
function(socute_append name str)
    if (NOT DEFINED ${PROJECT_IDENT}_${name})
        socute_declare_var(${name} "${str}" "" INTERNAL)
    else()
        socute_get(${name} vals)
        if (NOT "${str}" IN_LIST vals)
            list(APPEND vals "${str}")
            socute_set(${name} "${vals}")
        endif()
    endif()
endfunction()

# Prepend a value to a CACHE variable of list/string type
function(socute_prepend name str)
    if (NOT DEFINED ${PROJECT_IDENT}_${name})
        socute_declare_var(${name} "${str}" "" INTERNAL)
    else()
        socute_get(${name} vals)
        if (NOT "${str}" IN_LIST vals)
            list(PREPEND vals "${str}")
            socute_set(${name} "${vals}")
        endif()
    endif()
endfunction()

# Build the snakecase name for a string
function(socute_to_snakecase var out)
    string(REPLACE " " "_" txt "${var}")
    string(REGEX REPLACE "([A-Z])" "_\\1" txt "${txt}")
    string(TOLOWER "${txt}" txt)
    if (${txt} MATCHES "^_")
        string(SUBSTRING "${txt}" 1 -1 txt)
    endif()
    string(MAKE_C_IDENTIFIER "${txt}" txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build the snakecase name for a string
function(socute_to_hyphenated var out)
    socute_to_snakecase(${var} txt)
    string(REPLACE "_" "-" txt "${txt}")
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build a C identifier out of variable
function(socute_to_identifier var out)
    socute_to_snakecase(${var} txt)
    string(TOUPPER "${txt}" txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Find out the generated header path for the given target and suffix
function(socute_generated_header_path target suffix header_out)
    set(name "${target}${suffix}")
    socute_get(GENERATED_FILES_CASE case)
    if (case STREQUAL HYPHEN)
        socute_to_hyphenated("${name}" name)
    elseif (case STREQUAL SNAKE)
        socute_to_snakecase("${name}" name)
    endif()
    set(header_out "${CMAKE_CURRENT_BINARY_DIR}/${name}" PARENT_SCOPE)
endfunction()

# Build the export name of a target
function(socute_target_export_name target out)
    set(${out} "${target}" PARENT_SCOPE)
endfunction()

# Build the fullname of a short module name
function(socute_target_full_name target out)
    set(${out} "${PROJECT_NAME}${target}" PARENT_SCOPE)
endfunction()

# Build the alias name of a short module name
function(socute_target_alias_name target out)
    set(${out} "${PROJECT_NAME}::${target}" PARENT_SCOPE)
endfunction()

# Build the filename corresponding to a target
function(socute_target_file_name target out)
    socute_to_snakecase(${target} snake_target)
    socute_to_snakecase("${PROJECT_NAME}" txt)
    set(${out} "${txt}_${snake_target}" PARENT_SCOPE)
endfunction()

# Build the prefix to namespace C macros in generated headers for a given target
function(socute_target_identifier_name target out)
    socute_to_identifier(${target} id_target)
    socute_to_identifier("${PROJECT_NAME}" txt)
    set(${out} "${txt}_${id_target}" PARENT_SCOPE)
endfunction()

# cat in_file into out_file
function(socute_concat_file in_file out_file)
    file(READ "${in_file}" _contents)
    file(APPEND "${out_file}" "${_contents}")
endfunction()

# create a directory and ensure existence
function(socute_create_dir dir)
    file(MAKE_DIRECTORY "${dir}")
    if (NOT EXISTS "${dir}")
        message(FATAL_ERROR "could not find or make directory ${dir}")
    endif()
endfunction()

# The actual build type used to build external deps.
# for multiconfig generators, we choose an appropriate one, Release if possible
function(socute_external_build_type build_type)
    if (GENERATOR_IS_MULTI_CONFIG)
        if (Release IN_LIST CMAKE_CONFIGURATION_TYPES)
            set(_build_type Release)
        else()
            list(GET CMAKE_CONFIGURATION_TYPES 0 _build_type)
        endif()
    else()
        socute_get_or(EXTERNAL_BUILD_TYPE Release _build_type)
    endif()

    set(${build_type} "${_build_type}" PARENT_SCOPE)
endfunction()

# Create a config specific path that builds a subdirectory of prefix containing
# the compiler/syste$m/config triplet to ensure abi consistency.
function(_socute_config_specific_dir prefix out_dir)
    # default build type folder name
    socute_external_build_type(build_type)

    # System name
    string(TOLOWER "${build_type}" build_type)
    string(TOLOWER "${CMAKE_SYSTEM_NAME}" sys)
    string(TOLOWER "${CMAKE_CXX_COMPILER_ID}-${CMAKE_CXX_COMPILER_VERSION}" comp)
    socute_get(ARCH arch)
    set(datadir "${prefix}/${sys}-${comp}-x${arch}-${build_type}")

    # Ensure we can actually use this directory
    socute_create_dir("${datadir}")
    set(${out_dir} "${datadir}" PARENT_SCOPE)
endfunction()

# Get the root directory where all external packages will be handled.
# The fallback is ${PROJECT_BINARY_DIR}/external.
function(socute_external_root out_dir)
    set(fallback "${PROJECT_BINARY_DIR}/external")
    socute_get_or(EXTERNAL_ROOT "${fallback}" out)
    set(${out_dir} "${out}" PARENT_SCOPE)
endfunction()

# Get the download directory for external package archives to be saved.
# The fallback is ${socute_external_root}/download.
function(socute_external_download_root out_dir)
    socute_external_root(external_root)
    set(fallback "${external_root}/download")
    socute_get_or(DOWNLOAD_CACHE "${fallback}" out)
    set(${out_dir} "${out}" PARENT_SCOPE)
endfunction()

# The package-specific download dir
function(socute_external_download_dir pkg out_dir)
    socute_external_download_root(download_root)
    set(${out_dir} "${download_root}/${pkg}" PARENT_SCOPE)
endfunction()

# Where external packages source code is decompressed
function(socute_external_source_root out_dir)
    socute_external_root(external_root)
    set(${out_dir} "${external_root}/src" PARENT_SCOPE)
endfunction()

# The package-specific source dir
function(socute_external_source_dir pkg out_dir)
    socute_external_source_root(source_root)
    set(${out_dir} "${source_root}/${pkg}" PARENT_SCOPE)
endfunction()

# Where external packages source code is built
function(socute_external_build_root out_dir)
    socute_external_root(external_root)
    _socute_config_specific_dir("${external_root}/build" build_root)
    set(${out_dir} "${build_root}" PARENT_SCOPE)
endfunction()

# The package-specific build dir
function(socute_external_build_dir pkg out_dir)
    socute_external_build_root(build_root)
    set(${out_dir} "${build_root}/${pkg}" PARENT_SCOPE)
endfunction()

# Get the install prefix directory for external package.
# The fallback is ${socute_external_root}/prefix/${config_specific}.
function(socute_external_install_prefix out_dir)
    socute_external_root(external_root)
    _socute_config_specific_dir("${external_root}/prefix" fallback)
    socute_get_or(EXTERNAL_INSTALL_PREFIX "${fallback}" out)
    set(${out_dir} "${out}" PARENT_SCOPE)
endfunction()

function(socute_external_install_manifest_dir out_dir)
    socute_external_install_prefix(install_prefix)
    set(${out_dir} "${install_prefix}/share/socute/manifests" PARENT_SCOPE)
endfunction()
