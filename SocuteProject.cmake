# Initial configuration of a project
include_guard()
include(SocuteHelpers)
include(SocuteCompilerOptions)
include(SocuteFindPackage)

# Setup build type
function(_socute_setup_build_type)
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

# Setup install location if not already set
function(_socute_setup_install_prefix)
    if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        # Find out where to install stuff
        socute_external_install_prefix(install_prefix)
        set(CMAKE_INSTALL_PREFIX "${install_prefix}" CACHE PATH
            "Install path prefix, prepended onto install directories." FORCE)
    endif()
endfunction()

# Setup prefix path to include the external prefix containing self installed deps
function(_socute_setup_prefix_path)
    socute_external_install_prefix(dir)
    if (NOT dir IN_LIST CMAKE_PREFIX_PATH)
        socute_append_cached(CMAKE_PREFIX_PATH "${dir}")
    endif()
endfunction()

# Setup reasonable defaults for commonly set cmake variables
macro(_socute_setup_defaults)
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

    # Disable the package registry, which could mislead cmake into looking for
    # packages in unexpected derectories
    set(CMAKE_EXPORT_NO_PACKAGE_REGISTRY ON)
    set(CMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY ON)
    set(CMAKE_FIND_USE_PACKAGE_REGISTRY OFF)
endmacro()

# Variables that are used internally
function(_socute_setup_internal_variables)
    # The identifier that will be used to prefix many variables, internal as well as user-facing
    socute_to_identifier("${PROJECT_NAME}" ident)
    set(PROJECT_IDENT "${ident}" CACHE INTERNAL "")

    # List of paths where package files can be found, extensible with socute_add_package_module_dir()
    socute_set_project_var(PACKAGE_MODULES_DIRS "${CMAKE_CURRENT_LIST_DIR}/packages")

    # Where template files can be found
    socute_set_project_var(TEMPLATES_DIR "${CMAKE_CURRENT_LIST_DIR}/templates")

    # Where dependency files are manipulated
    socute_set_project_var(DEP_DIR "${PROJECT_BINARY_DIR}/socute.cmake/dep")

    # List of relative directory paths where headers are expected to be found in
    # order to correctly find and compute their install destination.
    socute_set_project_var(RELATIVE_HEADERS_DIRS "src;include;Src;Source;Include")

    # How to name generated files
    socute_set_project_var(HYPHENATE_GENERATED_FILES OFF)

    # A default standard because this is often desired
    socute_set_project_var(CPP_STANDARD cxx_std_17)

    # Nicer way of handling 32 or 64 bits
    if (CMAKE_CXX_SIZEOF_DATA_PTR EQUAL 8)
        socute_set_project_var(X64 ON)
        socute_set_project_var(X32 OFF)
        socute_set_project_var(ARCH 64)
    else()
        socute_set_project_var(X64 OFF)
        socute_set_project_var(X32 ON)
        socute_set_project_var(ARCH 32)
    endif()
endfunction()

# Diverses CMake options are defined here and can be used project-wide to alter
# the way the project is set up.
# Those are user-facing options, so we make sure to create nice option names.
function(_socute_declare_options)
    # Option to work offline
    socute_declare_option(OFFLINE OFF "Don't fetch dependency updates unless necessary")

    # Options that can be used to build optional stuff
    socute_declare_option(BUILD_EXAMPLES ON "Build optional examples")
    socute_declare_option(BUILD_TESTS ON "Build tests")
    socute_declare_option(BUILD_DOC ON "Build documentation")
    socute_declare_option(BUILD_BENCHMARKS OFF "Build benchmarks")

    # options that can alter the compilation
    socute_declare_option(ENABLE_AUTOSELECT_LINKER ON "Select the best available linker")
    socute_declare_option(ENABLE_COMMON_WARNINGS ON "Enable common compiler flags")
    socute_declare_option(ENABLE_LIBCXX OFF "Use libc++ instead of gcc standard library")
    socute_declare_option(ENABLE_LTO OFF "Enable link time optimization (release only)")
    socute_declare_option(ENABLE_MANY_WARNINGS OFF "Enable more compiler warnings")
    socute_declare_option(ENABLE_PROFILING OFF "Add compile flags to help with profiling")
    socute_declare_option(SANITIZE_ADDRESS OFF "Compile with address sanitizer support")
    socute_declare_option(SANITIZE_THREADS OFF "Compile with thread sanitizer support")
    socute_declare_option(SANITIZE_UNDEFINED OFF "Compile with undefined sanitizer support")
    socute_declare_option(KEEP_TEMPS OFF "Keep temporary compiler-generated files for debugging purpose")
    socute_declare_option(USE_CCACHE OFF "Use Ccache to speed-up compilation")

    # Setup a discoverable output dir to simplify program execution
    socute_declare_user_var(OUTPUT_DIRECTORY "" "Where to put all target files when built" PATH)

    # config option for documentation installation
    socute_declare_user_var(DOCUMENTATION_ROOT "" "Documentation installation root directory" PATH)
endfunction()

# Setup CMake with reasonable defaults
macro(socute_setup)
    _socute_setup_internal_variables()
    _socute_setup_build_type()
    _socute_setup_install_prefix()
    _socute_setup_prefix_path()
    _socute_setup_defaults()
    _socute_declare_options()
    _socute_setup_compiler_options()
    _socute_setup_build_dirs()
endmacro()

# Declare other files of the project in an "other files" category
function(socute_other_files)
    # We use a custom target because some IDEs can't cope with source_group
    if (NOT TARGET OtherFiles)
        add_custom_target(OtherFiles)
        set_target_properties(OtherFiles PROPERTIES PROJECT_LABEL "Other Files")
    endif()
    set_property(TARGET OtherFiles APPEND PROPERTY SOURCES ${ARGN})
endfunction()
