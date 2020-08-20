# Initial configuration of a project
include(GateauHelpers)
include(GateauCompilerOptions)
include(GateauParseArguments)

# Setup build type
function(_gateau_setup_build_type)
    if (GENERATOR_IS_MULTI_CONFIG)
        if (NOT CMAKE_CONFIGURATION_TYPES)
            set(CMAKE_CONFIGURATION_TYPES "Release;Debug" CACHE STRING "" FORCE)
        endif()
    else()
        if (NOT CMAKE_BUILD_TYPE)
            set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
        endif()
    endif()
endfunction()

# Setup prefix path to include the external prefix containing self installed deps
function(_gateau_setup_prefix_path)
    # no external deps: we don't alter the prefix path
    gateau_get(NO_BUILD_DEPS no_build_deps)
    if (no_build_deps)
        return()
    endif()

    gateau_external_install_prefix(dir)
    set(path ${CMAKE_PREFIX_PATH})
    if (NOT dir IN_LIST path)
        list(PREPEND path "${dir}")  # prepend to favor last change
        set(CMAKE_PREFIX_PATH "${path}" CACHE STRING "" FORCE)
    endif()
endfunction()

# Setup reasonable defaults for commonly set cmake variables
macro(_gateau_setup_defaults)
    # Static or Shared libraries
    # If the library type is not provided, we create static libraries in release mode
    # and dynamic libraries otherwise (linking is slow in debug, so we minimize it).
    if (NOT DEFINED BUILD_SHARED_LIBS)
        if (CMAKE_BUILD_TYPE STREQUAL "Release")
            set(BUILD_SHARED_LIBS OFF)
        else()
            set(BUILD_SHARED_LIBS ON)
        endif()
    endif()

    set(CMAKE_POSITION_INDEPENDENT_CODE ON)

    # IDE
    set_property(GLOBAL PROPERTY USE_FOLDERS ON)

    # Misc make options
    set(CMAKE_COLOR_MAKEFILE ON)
    set(CMAKE_VERBOSE_MAKEFILE ON)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # Rpath handling
    set(CMAKE_SKIP_BUILD_RPATH OFF)
    set(CMAKE_BUILD_WITH_INSTALL_RPATH OFF)
    set(CMAKE_INSTALL_RPATH_USE_LINK_PATH ON)
    if (APPLE)
        set(CMAKE_MACOSX_RPATH ON)
    endif()

    set(CMAKE_BUILD_RPATH_USE_ORIGIN ON)
    set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib:$ORIGIN/../lib64:$ORIGIN")

    # config mode should be preferred
    set(CMAKE_FIND_PACKAGE_PREFER_CONFIG ON)

    # Disable the package registry, which could mislead cmake into looking for
    # packages in unexpected derectories
    set(CMAKE_EXPORT_NO_PACKAGE_REGISTRY ON)
    set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY ON)
    set(CMAKE_FIND_USE_PACKAGE_REGISTRY OFF)
endmacro()

# Variables that are used internally
function(_gateau_setup_internal_variables)
    # The identifier that will be used to prefix many variables, internal as well as user-facing
    gateau_to_identifier("${PROJECT_NAME}" ident)
    set(${PROJECT_NAME}_IDENT "${ident}" CACHE INTERNAL "")

    # Project root dir
    gateau_declare_internal(ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}")

    # List of paths where package files can be found, extensible with gateau_add_package_module_dir()
    gateau_declare_internal(PACKAGE_MODULES_DIRS "${CMAKE_CURRENT_LIST_DIR}/packages")

    # Where template files can be found
    gateau_declare_internal(TEMPLATES_DIR "${CMAKE_CURRENT_LIST_DIR}/templates")

    # Where dependency files are manipulated
    gateau_declare_internal(DEP_DIR "${PROJECT_BINARY_DIR}/gateau.cmake/dep")

    # List of relative directory paths where headers are expected to be found in
    # order to correctly find and compute their install destination.
    gateau_declare_internal(RELATIVE_HEADERS_DIRS "src;include;Src;Source;Include")

    # How to name generated headers: possible values are CAMEL, SNAKE and HYPHEN
    gateau_declare_internal(GENERATED_HEADER_CASE CAMEL)
    set_property(CACHE ${ident}_GENERATED_HEADER_CASE PROPERTY STRINGS "CAMEL;SNAKE;HYPHEN")

    # generated headers extension
    gateau_declare_internal(GENERATED_HEADER_EXT "h")

    # A default standard because this is often desired
    gateau_declare_internal(C_STANDARD c_std_99)
    gateau_declare_internal(CXX_STANDARD cxx_std_17)

    # Nicer way of handling 32 or 64 bits
    if (CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
        gateau_declare_internal(X64 ON)
        gateau_declare_internal(X32 OFF)
        gateau_declare_internal(ARCH 64)
    else()
        gateau_declare_internal(X64 OFF)
        gateau_declare_internal(X32 ON)
        gateau_declare_internal(ARCH 32)
    endif()
endfunction()

# Diverses CMake options are defined here and can be used project-wide to alter
# the way the project is set up.
# Those are user-facing options, so we make sure to create nice option names.
function(_gateau_declare_options)
    # Options that can be used to build optional stuff
    gateau_declare_option(BUILD_EXAMPLES ON "Build optional examples")
    gateau_declare_option(BUILD_TESTS ON "Build tests")
    gateau_declare_option(BUILD_DOC ON "Build documentation")
    gateau_declare_option(BUILD_BENCHMARKS OFF "Build benchmarks")

    # options that can alter the compilation
    gateau_declare_option(ENABLE_AUTOSELECT_LINKER ON "Select the best available linker")
    gateau_declare_option(ENABLE_COMMON_WARNINGS ON "Enable common compiler flags")
    gateau_declare_option(ENABLE_WERROR ON "Enable werror for a few important compiler flags")
    gateau_declare_option(ENABLE_LIBCXX OFF "Use libc++ instead of gcc standard library")
    gateau_declare_option(ENABLE_LTO OFF "Enable link time optimization (release only)")
    gateau_declare_option(ENABLE_MANY_WARNINGS OFF "Enable more compiler warnings")
    gateau_declare_option(ENABLE_PROFILING OFF "Add compile flags to help with profiling")
    gateau_declare_option(SPLIT_DEBUG_INFO ON "Split debug info")
    gateau_declare_option(SANITIZE_ADDRESS OFF "Compile with address sanitizer support")
    gateau_declare_option(SANITIZE_THREADS OFF "Compile with thread sanitizer support")
    gateau_declare_option(SANITIZE_UNDEFINED OFF "Compile with undefined sanitizer support")
    gateau_declare_option(KEEP_TEMPS OFF "Keep temporary compiler-generated files for debugging purpose")
    gateau_declare_option(USE_CCACHE OFF "Use Ccache to speed-up compilation")

    # Allow/Update deps
    gateau_declare_option(NO_BUILD_DEPS OFF "Disable external dependency build and installation")
    gateau_declare_option(UPDATE_DEPS OFF "Fetch dependency updates each time the project is reconfigured")

    # Other options pertaining to output
    gateau_declare_var(OUTPUT_DIRECTORY "" "Where to put all target files when built" PATH)
    gateau_declare_var(DOCUMENTATION_ROOT "" "Documentation installation root directory" PATH)

    # External dependencies handling
    gateau_declare_var(EXTERNAL_BUILD_TYPE Release "Build type used to build external packages" STRING)
    gateau_declare_var(EXTERNAL_ROOT "" "Root directory where external packages get build" PATH)
    gateau_declare_var(EXTERNAL_INSTALL_PREFIX "" "Prefix where to install external packages" PATH)
    gateau_declare_var(DOWNLOAD_CACHE "" "Directory to store external packages code archives" PATH)
endfunction()

# Setup CMake with reasonable defaults
macro(gateau_init)
    _gateau_setup_internal_variables()
    _gateau_declare_options()
    _gateau_setup_build_dirs()
    _gateau_setup_build_type()
    _gateau_setup_defaults()
    _gateau_setup_prefix_path()
    _gateau_setup_compiler_options()

    # Some parts of Gateau may need to know if a parent project has already
    # performed an earlier initialization.
    set(_GATEAU_INIT_CALLED TRUE)
endmacro()

# Gateau offers a number of optional configuration options.
# This function is the recommended way of overriding those project-wide options from
# inside the main cmake list file. This is meant to be used by the project devs.
# The alternatives are setting the corresponding variables prior to inclusion of
# the main gateau module, or overriding the cache variables after inclusion.
# Users should set those options from the call to cmake at configure time.
function(gateau_configure)
    # Offering a single API call seems a more practical solution to setting a bunch of variables.
    set(bool_options
        NO_BUILD_DEPS
        UPDATE_DEPS
    )
    set(mono_options
        C_STANDARD
        CXX_STANDARD
        GENERATED_HEADER_CASE
        GENERATED_HEADER_EXT
        OUTPUT_DIRECTORY
        DOCUMENTATION_ROOT
        DOWNLOAD_CACHE
        EXTERNAL_BUILD_TYPE
        EXTERNAL_ROOT
        EXTERNAL_INSTALL_PREFIX
    )
    set(multi_options
        RELATIVE_HEADERS_DIRS
    )

    # All the variables are already defined, using gateau_parse_arguments allows
    # to obtain the current value if not set with gateau_configure()
    gateau_parse_arguments(_O "${${PROJECT_NAME}_IDENT}" "${bool_options}" "${mono_options}" "${multi_options}" ${ARGN})
    if (_O_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "Unrecognized arguments in gateau_configure(): ${_O_UNPARSED_ARGUMENTS}")
    endif()

    foreach(opt ${bool_options} ${mono_options} ${multi_options})
        gateau_set(${opt} "${_O_${opt}}")
    endforeach()

    # keep prefix path up to date
    _gateau_setup_prefix_path()
endfunction()

# Declare other files of the project in a "category" mock target
function(gateau_other_files category)
    # We use a custom target because some IDEs can't cope with source_group
    if (NOT TARGET ${category})
        add_custom_target(${category})
        set_target_properties(${category} PROPERTIES PROJECT_LABEL "${category}")
    endif()
    set_property(TARGET ${category} APPEND PROPERTY SOURCES ${ARGN})
endfunction()
