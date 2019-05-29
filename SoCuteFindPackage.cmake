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
function(_socute_update_prefix_path dir)
    # Find packages directories
    file(GLOB package_prefixes LIST_DIRECTORIES true "${dir}/*")

    foreach(prefix ${package_prefixes})
        if (IS_DIRECTORY "${prefix}")
            socute_append_cached(CMAKE_PREFIX_PATH "${prefix}/prefix")

            # Search paths are restricted in the toolchain files in cross-compile mode,
            # however our prefix directories are safe to use so we allow to use it from find_*
            socute_append_cached(CMAKE_FIND_ROOT_PATH "${prefix}/prefix")
        endif()
    endforeach()
endfunction()

# Look for a package file module for the given dependency name.
# It may either have the name "${name}.cmake" or be a template file with a name
# "${nameprefix}.cmake.in" that is a prefix of the name passed in argument
function(_socute_find_dependency_package_file name headers headers_dir out)
    # first look for exact name
    foreach (dir ${SOCUTE_PACKAGE_MODULE_DIRS})
        set(module_path "${dir}/${name}.cmake")
        if (EXISTS "${module_path}")
            set(${out} "${module_path}" PARENT_SCOPE)
            return()
        endif()
    endforeach()

    # Otherwise look for a template file that matches
    foreach (dir ${SOCUTE_PACKAGE_MODULE_DIRS})
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

                set(${out} "${module_path}" PARENT_SCOPE)
                return()
            endif()
        endforeach()
    endforeach()

    # if we handle a single header dependency, we may generate an appropriate
    # package file for that dependency.
    if (headers)
        set(module_path "${CMAKE_BINARY_DIR}/gen-modules/${name}.cmake")
        set(SOCUTE_PACKAGE_MODULE_NAME ${name})
        set(SOCUTE_PACKAGE_MODULE_HEADERS_FILES ${headers})
        set(SOCUTE_PACKAGE_MODULE_HEADERS_DIR ${headers_dir})
        configure_file("${SOCUTE_CMAKE_MODULES_DIR}/templates/HeadersOnlyPackageFile.cmake.in" "${module_path}" @ONLY)
        set(${out} "${module_path}" PARENT_SCOPE)
    else()
        # not found
        set(${out} "NOTFOUND" PARENT_SCOPE)
    endif()
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

# Macro that handles looking for packages and installing them in the right
# place if missing. It uses specially crafted modules (in the packages directory)
# containing directives that specify how to find and install said packages.
#
# NOTE: We use a macro because find_package() creates variables such as:
# ${package}_FOUND ${package}_LIBRARIES and ${package}_INCLUDE_DIRS that are not
# caches and would be limited unavailable if created inside a function scope.
macro(socute_find_package name)
    set(bool_options IN_SOURCE NO_EXTRACT NO_CONFIGURE NO_BUILD NO_INSTALL)
    set(mono_options GIT TAG URL MD5 PATCH_COMMAND CONFIGURE_COMMAND BUILD_COMMAND INSTALL_COMMAND HEADERS_DIR)
    set(multi_options CMAKE_ARGS HEADERS)
    cmake_parse_arguments(SAD "${bool_options};OPTIONAL" "${mono_options}" "${multi_options}" ${ARGN})

    # Prepare pathes
    socute_get_install_root(install_root)
    _socute_update_prefix_path("${install_root}")

    # try to find the dependency package file that contains instructions on how
    # to find and install a package
    _socute_find_dependency_package_file(${name} "${SAD_HEADERS}" "${SAD_HEADERS_DIR}" package_file)

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

        # Installation instructions can be either contained inside a package file
        # or directly in the arguments passed to this macro.
        # When both are available, the arguments passed to socute_add_dependency
        # are forwarded to the pkg_install macro of the package file, which, in
        # turn, will be responsible to handle these arguments
        if (package_file)
            include(${package_file})
        endif()

        # try to install from package file
        if (COMMAND ${name}_install)
            _socute_call_dynamic_macro(${name}_install ${name} ${opts})
        else()
            # default action is to call
            socute_install_dependency(${name} ${opts})
        endif()

        # update paths after installation
        _socute_update_prefix_path("${install_root}")

        # search again
        list(APPEND SAD_UNPARSED_ARGUMENTS "REQUIRED")
        _socute_find_dependency(${name} ${package_file} ${SAD_UNPARSED_ARGUMENTS})

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
endmacro()
