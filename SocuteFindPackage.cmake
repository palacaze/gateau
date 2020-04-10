# This module proposes a streamlined way of handling external package dependencies.
include_guard()
include(SocuteHelpers)
include(SocuteExternalPackage)

# Add a directory to the list of directories to search when looking for a
# package module file with installation instructions inside of it
function(socute_add_package_module_dir dir)
    socute_append_project_var(PACKAGE_MODULES_DIRS "${dir}")
endfunction()

# A number of files get generated for the purpose of dependency handling and
# other operations. This function ensures proper creation and cleanup of the
# directory structure that support those files
function(_socute_setup_build_dirs)
    set(_gen_dir "${PROJECT_BINARY_DIR}/socute.cmake")
    file(REMOVE_RECURSE "${_gen_dir}")
    socute_create_dir("${_gen_dir}/dep/package-modules")
    socute_create_dir("${_gen_dir}/dep/call-helpers")
endfunction()

# Look for a package file module for the given dependency name.
# It may either have the name "${name}.cmake" or be a template file with a name
# "${nameprefix}.cmake.in" that is a prefix of the name passed in argument
function(_socute_find_dep_package_file name package_file)
    get_filename_component(_pm_dir "${package_file}" DIRECTORY)
    set(_pm_dir "${_dep_dir}/package-modules")

    # first look for exact name
    socute_get_project_var(PACKAGE_MODULES_DIRS mod_dirs)
    foreach (dir ${mod_dirs})
        set(module_path "${dir}/${name}.cmake")
        if (EXISTS "${module_path}")
            file(COPY "${module_path}" DESTINATION "${_pm_dir}")
            break()
        endif()
    endforeach()

    # Otherwise look for a template file that matches
    foreach (dir ${mod_dirs})
        if (EXISTS "${package_file}")
            break()
        endif()

        file(GLOB_RECURSE file_templates RELATIVE "${dir}" "${dir}/*.cmake.in")

        foreach (templ ${file_templates})
            string(REPLACE ".cmake.in" "" templ_prefix "${templ}")

            # we got a matching template name
            if (name MATCHES "^${templ_prefix}")
                # generate a module file from the template
                set(SOCUTE_PACKAGE_MODULE_NAME ${name})
                configure_file("${dir}/${templ}" "${package_file}" @ONLY)
                unset(SOCUTE_PACKAGE_MODULE_NAME)
                break()
            endif()
        endforeach()
    endforeach()
endfunction()

# Prepare a package file module, which contains instructions on how the package
# whose name has been passed as first argument should be found and/or installed.
# It may either have the name "${name}.cmake" or be a template file with a name
# "${nameprefix}.cmake.in" that is a prefix of the name passed in argument.
# If single_header is not empty, a package file will be generated for it.
function(_socute_prepare_dep_package_file name single_header out)
    socute_get_project_var(TEMPLATES_DIR _templates)
    socute_get_project_var(DEP_DIR _dep_dir)
    set(_pm_dir "${_dep_dir}/package-modules")

    # The package file to create
    set(_package_file "${_pm_dir}/${name}.cmake")

    # Try to find one in the package directories
    _socute_find_dep_package_file(${name} "${_package_file}")

    # if we handle a single header dependency, we have to generate an appropriate
    # package file. In order to know if we are dealing with a single header, we
    # may need to source a previously found package file to find out.
    if (EXISTS "${_package_file}")
        include("${_package_file}")
    endif()

    if (single_header)
        set(${name}_SINGLE_HEADER "${single_header}")
    endif()

    # build a package_file from a template with consideration to potentially
    # existing hand made custom package file to be prepended to the generated one.
    if (${name}_SINGLE_HEADER)
        set(SOCUTE_PACKAGE_MODULE_NAME ${name})
        set(SOCUTE_PACKAGE_MODULE_SINGLE_HEADER_FILE ${${name}_SINGLE_HEADER})
        configure_file("${_templates}/SingleHeaderPackageFile.cmake.in" "${_package_file}.tmp" @ONLY)
        socute_concat_file("${_package_file}.tmp" "${_package_file}")
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
        set(_gen_dir "${PROJECT_BINARY_DIR}/socute.cmake")
        set(_helper "${_gen_dir}/dep/call-helpers/dynamic_helper_${macro_name}.cmake")
        set(_args "${ARGN}")
        file(WRITE "${_helper}" "${macro_name}(${_args})")
        include("${_helper}")
    endif()

    unset(_gen_dir)
    unset(_args)
    unset(_helper)
endmacro()

# If we installed a dependency ourselves, we can expose useful targets for this
# dependency: update, reinstall and uninstall.
function(_socute_configure_dep_targets name)
    if (${name}_DIR AND IS_DIRECTORY "${${name}_DIR}")
        # We check that the dep is ours (it is in our external install prefix)
        socute_external_install_prefix(install_prefix)
        get_filename_component(install_prefix "${install_prefix}" REALPATH)
        get_filename_component(_dir "${${name}_DIR}" REALPATH)
        if(_dir MATCHES "${install_prefix}")
            socute_configure_uninstall_target(${name})
            socute_configure_update_reinstall_targets(${name})

            # reinstall will be preceded by uninstall if available
            if (TARGET uninstall_${name} AND TARGET reinstall_${name})
                add_dependencies(reinstall_${name} uninstall_${name})
            endif()
        endif()
    endif()
endfunction()

# Append find instructions for this dep to a module that will be installed along
# with the project.
function(_socute_register_dep name package_file)
    list(JOIN ARGN " " args)

    socute_get_project_var(DEP_DIR _dep_dir)
    set(_dep_module "${_dep_dir}/${PROJECT_NAME}FindDeps.cmake")

    # we add the package DIR to the module path if we installed it ourselves
    socute_get_project_var(INSTALLED_PACKAGES self_installed)
    if (name IN_LIST self_installed AND ${name}_DIR)
        file(APPEND "${_dep_module}" "set(${name}_DIR \"${${name}_DIR}\")\n")
    endif()

    if (EXISTS "${package_file}")
        socute_concat_file("${package_file}" "${_dep_module}")
    endif()

    if (COMMAND ${name}_find)
        string(CONFIGURE "@name@_find(@name@ @args@)" cmd @ONLY)
    else()
        string(CONFIGURE "find_package(@name@ @args@)" cmd @ONLY)
    endif()

    file(APPEND "${_dep_module}" "${cmd}\n")
endfunction()

# Try to find a dependency
# There are two ways of doing this: either using a custom pkg_find() macro that
# may be supplied in a previously sourced package file, or from a standard call
# to find_package.
macro(_socute_find_dep_wrapper name)
    if (COMMAND ${name}_find)
        _socute_call_dynamic_macro(${name}_find ${name} ${ARGN})
    else()
        find_package(${name} ${ARGN})
    endif()
endmacro()

# Perform actual installation of a package
# Installation instructions can be either contained inside a package file
# or directly in the arguments passed to this macro.
# When both are available, the arguments passed to _socute_install_dep_wrapper
# are forwarded to the pkg_install macro of the package file, which, in
# turn, will be responsible to handle these arguments
function(_socute_install_dep_wrapper name)
    # try to install from package file
    if (COMMAND ${name}_install)
        _socute_call_dynamic_macro(${name}_install ${name} ${ARGN})
    else()
        # default action is to call install_dependency
        socute_install_dependency(${name} ${ARGN})
    endif()

    socute_append_project_var(INSTALLED_PACKAGES ${name})
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
    set(mono_options GIT TAG URL MD5 SOURCE_SUBDIR)
    set(multi_options CMAKE_CACHE_ARGS CMAKE_ARGS PATCH_COMMAND UPDATE_COMMAND CONFIGURE_COMMAND BUILD_COMMAND INSTALL_COMMAND)
    cmake_parse_arguments(_O
        "${bool_options};OPTIONAL;BUILD_DEP"
        "${mono_options};SINGLE_HEADER"
        "${multi_options}"
        ${ARGN}
    )

    # Try to find the dependency package file that contains instructions on how
    # to find and install a package. Then we source it.
    # Also handle the single header special-case
    _socute_prepare_dep_package_file(${name} "${_O_SINGLE_HEADER}" package_file)
    if (EXISTS "${package_file}")
        include("${package_file}")
    endif()

    # try to find the dependency
    _socute_find_dep_wrapper(${name} ${_O_UNPARSED_ARGUMENTS} QUIET)

    # not found, we will try to install it and search again
    if (NOT ${name}_FOUND AND NOT _O_OPTIONAL)
        # build option list from arguments
        socute_rebuild_parsed(_O "${bool_options}" "${mono_options}" "${multi_options}" _opts)

        # perform installation
        _socute_install_dep_wrapper(${name} ${_opts})

        # search again
        _socute_find_dep_wrapper(${name} ${_O_UNPARSED_ARGUMENTS} REQUIRED)

        if (NOT ${name}_FOUND)
            message(FATAL_ERROR "Installation of package '${name}' failed.")
        endif()
    endif()

    # configure custom targets for this dep if some are available
    if (${name}_FOUND)
        _socute_configure_dep_targets(${name})
    endif()

    # Register this package as a required dependency for software that will use
    # our project, unless it has been marked as a build-only dep.
    if (${name}_FOUND AND NOT _O_BUILD_DEP)
        _socute_register_dep(${name} "${package_file}" ${_O_UNPARSED_ARGUMENTS})
    endif()

    # We are a macro, unset everything
    socute_cleanup_parsed(_O "${bool_options}" "${mono_options}" "${multi_options}")
    unset(bool_options)
    unset(mono_options)
    unset(multi_options)
    unset(_opts)
    unset(package_file)
endmacro()
