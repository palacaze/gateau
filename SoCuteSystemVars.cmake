# Compiler name
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(SOCUTE_COMPILER_CLANG ON)
    set(SOCUTE_COMPILER_NAME "clang")
elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    set(SOCUTE_COMPILER_GCC ON)
    set(SOCUTE_COMPILER_NAME "gcc")
elseif (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
    set(SOCUTE_COMPILER_MSVC ON)
    set(SOCUTE_COMPILER_NAME "msvc")
endif()

if (SOCUTE_COMPILER_CLANG OR SOCUTE_COMPILER_GCC)
    set(SOCUTE_COMPILER_CLANG_OR_GCC ON)
endif()

# Compiler version
set(SOCUTE_COMPILER_VERSION "${CMAKE_CXX_COMPILER_VERSION}")

# System name
string(TOLOWER "${CMAKE_SYSTEM_NAME}" SOCUTE_SYSTEM_NAME)

# System version
if (SOCUTE_SYSTEM_NAME MATCHES "linux")
    # Special handling for linux, we want per distro name and appropriate version
    if (NOT DEFINED SOCUTE_SYSTEM_VERSION)
        # for linux we distinguish per distribution (flavour)
        find_program(LSB_RELEASE_EXEC lsb_release REQUIRED)

        execute_process(COMMAND ${LSB_RELEASE_EXEC} -is
            OUTPUT_VARIABLE SOCUTE_SYSTEM_FLAVOUR
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        string(TOLOWER "${SOCUTE_SYSTEM_FLAVOUR}" SOCUTE_SYSTEM_FLAVOUR)
        set(SOCUTE_SYSTEM_FLAVOUR ${SOCUTE_SYSTEM_FLAVOUR} CACHE INTERNAL "")

        execute_process(COMMAND ${LSB_RELEASE_EXEC} -rs
            OUTPUT_VARIABLE SOCUTE_SYSTEM_VERSION
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(SOCUTE_SYSTEM_VERSION ${SOCUTE_SYSTEM_VERSION} CACHE INTERNAL "")
    endif()
else()
    set(SOCUTE_SYSTEM_FLAVOUR "${SOCUTE_SYSTEM_NAME}")
    set(SOCUTE_SYSTEM_VERSION "${CMAKE_SYSTEM_VERSION}")
endif()

# 32 or 64 bits
if (CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
    set(SOCUTE_X64 ON)
    set(SOCUTE_X32 OFF)
    set(SOCUTE_ARCH 64)
else()
    set(SOCUTE_X64 OFF)
    set(SOCUTE_X32 ON)
    set(SOCUTE_ARCH 32)
endif()

# where we put generated files
function(socute_generated_dir out)
    socute_to_subfolder("${SOCUTE_PACKAGE}" package_subfolder)
    set(${out} "${CMAKE_BINARY_DIR}/src/${package_subfolder}" PARENT_SCOPE)
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
        if (SOCUTE_EXTERNAL_BUILD_TYPE)
            set(_build_type "${SOCUTE_EXTERNAL_BUILD_TYPE}")
        else()
            set(_build_type "${CMAKE_BUILD_TYPE}")
        endif()
    endif()

    set(${build_type} "${_build_type}" PARENT_SCOPE)
endfunction()

# Get the root directory where all external packages will be installed
# SOCUTE_EXTERNAL_ROOT may be supplied to cmake at configure time, otherwise the
# environment variable of the same name will be picked. At last the fallback will
# be ${SOCUTE_BINARY_DIR}/external.
function(socute_get_external_root dir)
    if (NOT DEFINED SOCUTE_EXTERNAL_ROOT)
        set(SOCUTE_EXTERNAL_ROOT "$ENV{SOCUTE_EXTERNAL_ROOT}")
        if (NOT SOCUTE_EXTERNAL_ROOT)
            set(SOCUTE_EXTERNAL_ROOT "${CMAKE_BINARY_DIR}/external")
        endif()
    endif()

    set(${dir} "${SOCUTE_EXTERNAL_ROOT}" PARENT_SCOPE)
endfunction()

# Create a config specific path that builds a subdirectory of prefix containing
# the compiler/system/config triplet to ensure abi consistency.
function(_socute_config_specific_dir prefix out_dir)
    # default build type folder name
    socute_external_build_type(build_type_folder)

    # Compose full path
    set(sys "${SOCUTE_SYSTEM_FLAVOUR}-${SOCUTE_SYSTEM_VERSION}")
    set(comp "${SOCUTE_COMPILER_NAME}-${SOCUTE_COMPILER_VERSION}")
    set(datadir "${prefix}/${sys}/${comp}/${build_type_folder}")

    # Ensure we can actually use this directory
    socute_create_dir("${datadir}")
    set(${out_dir} "${datadir}" PARENT_SCOPE)
endfunction()

# Get the root directory where all external packages will be handled
# SOCUTE_EXTERNAL_ROOT may be supplied to cmake at configure time, or as an
# environment variable of the same name.
# The fallback is ${SOCUTE_BINARY_DIR}/external.
function(socute_external_root out_dir)
    if (NOT DEFINED SOCUTE_EXTERNAL_ROOT)
        set(SOCUTE_EXTERNAL_ROOT "$ENV{SOCUTE_EXTERNAL_ROOT}")
        if (NOT SOCUTE_EXTERNAL_ROOT)
            set(SOCUTE_EXTERNAL_ROOT "${CMAKE_BINARY_DIR}/external")
        endif()
    endif()

    set(${out_dir} "${SOCUTE_EXTERNAL_ROOT}" PARENT_SCOPE)
endfunction()

# Get the download directory for external package archives to be saved.
# SOCUTE_DOWNLOAD_CACHE may be supplied to cmake at configure time, or as an
# environment variable of the same name.
# The fallback is ${socute_external_root}/download.
function(socute_external_download_root out_dir)
    if (NOT DEFINED SOCUTE_DOWNLOAD_CACHE)
        set(SOCUTE_DOWNLOAD_CACHE "$ENV{SOCUTE_DOWNLOAD_CACHE}")
        if (NOT SOCUTE_DOWNLOAD_CACHE)
            socute_external_root(external_root)
            set(SOCUTE_DOWNLOAD_CACHE "${external_root}/download")
        endif()
    endif()

    set(${out_dir} "${SOCUTE_DOWNLOAD_CACHE}" PARENT_SCOPE)
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

# Get the install root directory for external package.
# SOCUTE_EXTERNAL_INSTALL_PREFIX may be supplied to cmake at configure time,
# or as an environment variable of the same name.
# The fallback is ${socute_external_root}/prefix/${config_specific}.
function(socute_external_install_root out_dir)
    if (NOT DEFINED SOCUTE_EXTERNAL_INSTALL_PREFIX)
        set(SOCUTE_EXTERNAL_INSTALL_PREFIX "$ENV{SOCUTE_EXTERNAL_INSTALL_PREFIX}")
        if (NOT SOCUTE_EXTERNAL_INSTALL_PREFIX)
            socute_external_root(external_root)
            _socute_config_specific_dir("${external_root}/prefix" SOCUTE_EXTERNAL_INSTALL_PREFIX)
        endif()
    endif()

    set(${out_dir} "${SOCUTE_EXTERNAL_INSTALL_PREFIX}" PARENT_SCOPE)
endfunction()

# The package-specific install dir.
function(socute_external_install_dir pkg out_dir)
    socute_external_install_root(install_root)
    set(${out_dir} "${install_root}/${pkg}" PARENT_SCOPE)
endfunction()
