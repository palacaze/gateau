# This module proposes a streamlined way of handling external package dependencies.

include(SoCuteHelpers)
include(SoCuteSystemVars)
include(SoCuteExternalPackage)

# Add a directory to the list of directories to search when looking for a
# package module file with installation instructions inside of it
function(socute_add_package_module_dir dir)
    socute_append_cached(SOCUTE_PACKAGE_MODULE_DIRS "${dir}")
endfunction()

# List directories in ${dir} and append them into CMAKE_PREFIX_PATH
# Theses directories contain external packages installed in their own prefix dir.
function(_socute_update_prefix_path)
    # Find packages directories
    socute_external_install_root(dir)
    file(GLOB package_prefixes LIST_DIRECTORIES true "${dir}/*")

    foreach(prefix ${package_prefixes})
        if (IS_DIRECTORY "${prefix}")
            socute_append_cached(CMAKE_PREFIX_PATH "${prefix}")

            # Search paths are restricted in the toolchain files in cross-compile mode,
            # however our prefix directories are safe to use so we allow to use it from find_*
            socute_append_cached(CMAKE_FIND_ROOT_PATH "${prefix}")
        endif()
    endforeach()
endfunction()

# Look for a package file module for the given dependency name.
# It may either have the name "${name}.cmake" or be a template file with a name
# "${nameprefix}.cmake.in" that is a prefix of the name passed in argument
function(_socute_find_dependency_package_file name single_header out)
    set(_package_file "NOTFOUND")

    # first look for exact name
    foreach (dir ${SOCUTE_PACKAGE_MODULE_DIRS})
        set(module_path "${dir}/${name}.cmake")
        if (EXISTS "${module_path}")
            set(_package_file "${module_path}")
            break()
        endif()
    endforeach()

    # Otherwise look for a template file that matches
    foreach (dir ${SOCUTE_PACKAGE_MODULE_DIRS})
        if (_package_file)
            break()
        endif()

        file(GLOB_RECURSE file_templates RELATIVE "${dir}" "${dir}/*.cmake.in")

        foreach (templ ${file_templates})
            string(REPLACE ".cmake.in" "" templ_prefix "${templ}")

            # we got a matching template name
            if (name MATCHES "^${templ_prefix}")
                # generate a module file from the template
                set(module_path "${CMAKE_BINARY_DIR}/gen-modules/${name}.cmake")
                set(SOCUTE_PACKAGE_MODULE_NAME ${name})
                configure_file("${dir}/${templ}" "${module_path}" @ONLY)
                unset(SOCUTE_PACKAGE_MODULE_NAME)

                set(_package_file "${module_path}")
                break()
            endif()
        endforeach()
    endforeach()

    # if we handle a single header dependency, we have to generate an appropriate
    # package file
    if (_package_file)
        include(${_package_file})
    endif()

    if (single_header)
        set(${name}_SINGLE_HEADER "${single_header}")
    endif()

    # build a package_file from a template with consideration to potentially
    # existing hand made custom package file to be prepended to the generated one.
    if (${name}_SINGLE_HEADER)
        set(module_path "${CMAKE_BINARY_DIR}/gen-modules/${name}.cmake")

        if (_package_file)
            file(COPY ${_package_file} DESTINATION "${CMAKE_BINARY_DIR}/gen-modules")
        endif()

        set(SOCUTE_PACKAGE_MODULE_NAME ${name})
        set(SOCUTE_PACKAGE_MODULE_SINGLE_HEADER_FILE ${${name}_SINGLE_HEADER})
        configure_file("${SOCUTE_CMAKE_MODULES_DIR}/templates/HeadersOnlyPackageFile.cmake.in" "${module_path}.tmp" @ONLY)
        socute_concat_file("${module_path}.tmp" "${module_path}")
        set(_package_file "${module_path}")
    endif()

    set(${out} "${_package_file}" PARENT_SCOPE)
endfunction()

# Cmake does not support dynamic macro names, ie we can't have a macro whose name
# is computed, for instance ${name}_find and call it like this: ${name}_find()
# Whoever, we can create a module with a wrapper macro with fixed name that forwards
# the call to this dynamic macro, by writing it to disk and call including it.
# This is what we will be doing here, by wrapping ${name}_find and ${name}_install
macro(_socute_call_dynamic_macro macro_name)
    if (NOT COMMAND ${macro_name})
        message(FATAL_ERROR "Unknown macro \"${macro_name}\"")
    else()
        set(_helper "${CMAKE_BINARY_DIR}/helpers/dynamic_macro_helper_${macro_name}.cmake")
        set(_args "${ARGN}")
        file(WRITE "${_helper}" "${macro_name}(${_args})")
        include("${_helper}")
    endif()

    unset(_args)
    unset(_helper)
endmacro()

# Declare a dependency to have been found
# This will be used later on to simplify installation and export of the package
function(_socute_register_dependency name package_file)
    list(JOIN ARGN " " args)

    if (package_file AND COMMAND ${name}_find)
        # record the package file for later in a cache variable
        socute_append_cached(SOCUTE_PACKAGE_CONFIG_FIND_MODULE ${package_file})

        # record the command that was called to look for the package
        # put a ||| separator in the command because the cache file can't handle newlines
        get_filename_component(module_name "${package_file}" NAME_WE)
        string(CONFIGURE "include(@module_name@)|||@name@_find(@name@ @args@)" cmd @ONLY)

    else()
        string(CONFIGURE "find_package(@name@ @args@)" cmd @ONLY)
    endif()

        socute_append_cached(SOCUTE_PACKAGE_CONFIG_FIND_CMD ${cmd})
endfunction()

# Try to find a dependency
# There are two ways of doing this: either using a custom pkg_find() macro that
# may be supplied in a package file, or from a standard call to find_package otherwise.
macro(_socute_find_dependency name package_file)
    # In case we installed this dependency previously, we search the expected install dir too
    _socute_update_prefix_path()

    if (package_file)
        include(${package_file})
        if (COMMAND ${name}_find)
            _socute_call_dynamic_macro(${name}_find ${name} ${ARGN})
        else()
            find_package(${name} ${ARGN})
        endif()
    else()
        find_package(${name} ${ARGN})
    endif()
endmacro()

# Perform actual installation of a package
# Installation instructions can be either contained inside a package file
# or directly in the arguments passed to this macro.
# When both are available, the arguments passed to socute_add_dependency
# are forwarded to the pkg_install macro of the package file, which, in
# turn, will be responsible to handle these arguments
function(_socute_do_install_dependency name package_file)
    if (package_file)
        include(${package_file})
    endif()

    # try to install from package file
    if (COMMAND ${name}_install)
        _socute_call_dynamic_macro(${name}_install ${name} ${ARGN})
    else()
        # default action is to call install_dependency
        socute_install_dependency(${name} ${ARGN})
    endif()
endfunction()

# Macro that handles looking for packages and installing them in the right
# place if missing. It uses specially crafted modules (in the packages directory)
# containing directives that specify how to find and install said packages.
#
# NOTE: We use a macro because find_package() creates variables such as:
# ${package}_FOUND ${package}_LIBRARIES and ${package}_INCLUDE_DIRS that are not
# caches and would be limited unavailable if created inside a function scope.
macro(socute_find_package name)
    set(bool_options IN_SOURCE NO_EXTRACT NO_PATCH NO_UPDATE NO_CONFIGURE NO_BUILD NO_INSTALL)
    set(mono_options GIT TAG URL MD5 SINGLE_HEADER SOURCE_SUBDIR)
    set(multi_options CMAKE_ARGS PATCH_COMMAND UPDATE_COMMAND CONFIGURE_COMMAND BUILD_COMMAND INSTALL_COMMAND)
    cmake_parse_arguments(SAD "${bool_options};OPTIONAL" "${mono_options}" "${multi_options}" ${ARGN})

    # try to find the dependency package file that contains instructions on how
    # to find and install a package. Also handle the single header special-case
    _socute_find_dependency_package_file(${name} "${SAD_SINGLE_HEADER}" package_file)
    unset(SAD_SINGLE_HEADER)

    # try to find the dependency
    _socute_find_dependency(${name} ${package_file} ${SAD_UNPARSED_ARGUMENTS} QUIET)

    # not found, we will try to install it and search again
    if (NOT ${name}_FOUND AND NOT SAD_OPTIONAL)
        # build option list from arguments
        foreach(opt ${bool_options})
            if (SAD_${opt})
                list(APPEND opts ${opt})
            endif()
        endforeach()
        foreach(opt ${mono_options} ${multi_options})
            if (SAD_${opt})
                list(APPEND opts ${opt} ${SAD_${opt}})
            endif()
        endforeach()

        # perform installation
        _socute_do_install_dependency(${name} ${package_file} ${opts})

        # search again
        _socute_find_dependency(${name} ${package_file} ${SAD_UNPARSED_ARGUMENTS} REQUIRED)

        if (NOT ${name}_FOUND)
            message(FATAL_ERROR "Installation of package '${name}' failed.")
        endif()
    endif()

    # Register this package as a required dependency for software that will
    # use our project
    if (${name}_FOUND)
        _socute_register_dependency(${name} ${package_file} ${SAD_UNPARSED_ARGUMENTS})
    endif()

    # We are a macro, unset everything
    foreach(opt ${bool_options} ${mono_options} ${multi_options})
        unset(SAD_${opt})
    endforeach()
    unset(SAD_UNPARSED_ARGUMENTS)
    unset(bool_options)
    unset(mono_options)
    unset(multi_options)
    unset(opt)
    unset(opts)
    unset(package_file)
endmacro()
