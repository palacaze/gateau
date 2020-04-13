# This module proposes a streamlined way of handling external package dependencies.
include_guard()
include(GateauHelpers)
include(GateauExternalPackage)

# Add a directory to the list of directories to search when looking for a
# package module file with installation instructions inside of it
function(gateau_add_package_module_dir dir)
    gateau_prepend(PACKAGE_MODULES_DIRS "${dir}")
endfunction()

# A number of files get generated for the purpose of dependency handling and
# other operations. This function ensures proper creation and cleanup of the
# directory structure that support those files
function(_gateau_setup_build_dirs)
    gateau_get(DEP_DIR _dep_dir)
    file(REMOVE_RECURSE "${_dep_dir}")
endfunction()

# Decide if a dep has been installed by us
function(_gateau_is_dep_in_install_prefix name test_out)
    # Assuming the dep has been found, the heuristic is to test a number of
    # variables known to be commonly defined by find_package and test if they
    # point to a subpath of the install prefix.
    gateau_external_install_prefix(install_prefix)
    get_filename_component(install_prefix "${install_prefix}" REALPATH)

    foreach (v DIR INCLUDE_DIR INCLUDE_DIRS LIBRARY LIBRARIES)
        set(_path ${name}_${v})
        if (DEFINED ${_path} AND EXISTS "${${_path}}")
            # We check that the dep is ours (it is in our external install prefix)
            get_filename_component(_path "${${_path}}" REALPATH)
            if(_path MATCHES "${install_prefix}")
                set(${test_out} TRUE PARENT_SCOPE)
                return()
            endif()
        endif()
    endforeach()

    set(${test_out} FALSE PARENT_SCOPE)
endfunction()

# Look for a package file module for the given dependency name.
# It may either have the name "${name}.cmake" or be a template file with a name
# "${nameprefix}.cmake.in" that is a prefix of the name passed in argument
function(_gateau_find_dep_package_file name package_file)
    get_filename_component(_pm_dir "${package_file}" DIRECTORY)

    # first look for exact name
    gateau_get(PACKAGE_MODULES_DIRS mod_dirs)
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
                set(GATEAU_PACKAGE_MODULE_NAME ${name})
                configure_file("${dir}/${templ}" "${package_file}" @ONLY)
                unset(GATEAU_PACKAGE_MODULE_NAME)
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
function(_gateau_prepare_dep_package_file name single_header out)
    gateau_get(TEMPLATES_DIR _templates)
    gateau_get(DEP_DIR _dep_dir)
    set(_pm_dir "${_dep_dir}/package-modules")
    gateau_create_dir("${_pm_dir}")

    # The package file to create
    set(_package_file "${_pm_dir}/${name}.cmake")

    # Try to find one in the package directories
    _gateau_find_dep_package_file(${name} "${_package_file}")

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
        set(GATEAU_PACKAGE_MODULE_NAME ${name})
        set(GATEAU_PACKAGE_MODULE_SINGLE_HEADER_FILE ${${name}_SINGLE_HEADER})
        configure_file("${_templates}/SingleHeaderPackageFile.cmake.in" "${_package_file}.tmp" @ONLY)
        gateau_concat_file("${_package_file}.tmp" "${_package_file}")
    endif()

    set(${out} "${_package_file}" PARENT_SCOPE)
endfunction()

# Cmake does not support dynamic macro names, ie we can't have a macro whose name
# is computed, for instance ${name}_find and call it like this: ${name}_find()
# Whoever, we can create a module with a wrapper macro with fixed name that forwards
# the call to this dynamic macro, by writing it to disk and call including it.
# This is what we will be doing here, by wrapping ${name}_find and ${name}_install
macro(_gateau_call_dynamic_macro macro_name)
    if (NOT COMMAND ${macro_name})
        message(FATAL_ERROR "Unknown macro \"${macro_name}\"")
    else()
        gateau_get(DEP_DIR _dep_dir)
        gateau_create_dir("${_dep_dir}/call-helpers")
        set(_helper "${_dep_dir}/call-helpers/dynamic_helper_${macro_name}.cmake")
        set(_args "${ARGN}")
        file(WRITE "${_helper}" "${macro_name}(${_args})")
        include("${_helper}")
    endif()

    unset(_dep_dir)
    unset(_args)
    unset(_helper)
endmacro()

# If we installed a dependency ourselves, we can expose useful targets for this
# dependency: update, reinstall and uninstall.
function(_gateau_configure_dep_targets name)
    _gateau_is_dep_in_install_prefix(${name} in_install_prefix)
    if (in_install_prefix)
        gateau_configure_uninstall_target(${name})
        gateau_configure_update_reinstall_targets(${name})

        # reinstall will be preceded by uninstall if available
        if (TARGET uninstall_${name} AND TARGET reinstall_${name})
            add_dependencies(reinstall_${name} uninstall_${name})
        endif()
    endif()
endfunction()

# Maybe update a dep, if it is ours
function(_gateau_maybe_update_dep name)
    # We check that the dep is ours (it is in our external install prefix)
    if (${name}_DIR AND IS_DIRECTORY "${${name}_DIR}")
        gateau_external_install_prefix(install_prefix)
        get_filename_component(install_prefix "${install_prefix}" REALPATH)
        get_filename_component(_dir "${${name}_DIR}" REALPATH)
        if(_dir MATCHES "${install_prefix}")
            gateau_update_dep(${name})
        endif()
    endif()
endfunction()

# Append find instructions for this dep to a module that will be installed along
# with the project.
function(_gateau_register_dep name package_file)
    list(JOIN ARGN " " args)

    gateau_get(DEP_DIR _dep_dir)
    set(_dep_module "${_dep_dir}/${PROJECT_NAME}FindDeps.cmake")

    # we add the package DIR to the module path if we installed it ourselves
    gateau_get(INSTALLED_PACKAGES self_installed)
    if (name IN_LIST self_installed AND ${name}_DIR)
        file(APPEND "${_dep_module}" "set(${name}_DIR \"${${name}_DIR}\")\n")
    endif()

    if (EXISTS "${package_file}")
        gateau_concat_file("${package_file}" "${_dep_module}")
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
macro(_gateau_find_dep_wrapper name)
    if (COMMAND ${name}_find)
        _gateau_call_dynamic_macro(${name}_find ${name} ${ARGN})
    else()
        find_package(${name} ${ARGN})
    endif()
endmacro()

# Perform actual installation of a package
# Installation instructions can be either contained inside a package file
# or directly in the arguments passed to this macro.
# When both are available, the arguments passed to _gateau_install_dep_wrapper
# are forwarded to the pkg_install macro of the package file, which, in
# turn, will be responsible to handle these arguments
function(_gateau_install_dep_wrapper name)
    # try to install from package file
    if (COMMAND ${name}_install)
        _gateau_call_dynamic_macro(${name}_install ${name} ${ARGN})
    else()
        # default action is to call install_dependency
        gateau_install_dependency(${name} ${ARGN})
    endif()

    gateau_append(INSTALLED_PACKAGES ${name})
endfunction()

# Reset cache variables for a package if some of the files or dirs are missing
function(_gateau_reset_find_package name)
    set(do_reset FALSE)
    set(paths DIR INCLUDE_DIR INCLUDE_DIRS LIBRARY LIBRARIES)
    foreach (var ${paths})
        if (${name}_${var})
            foreach (lib ${${name}_${var}})
                if (NOT EXISTS "${lib}")
                    set(do_reset TRUE)
                    break()
                endif()
            endforeach()
        endif()
    endforeach()
    if (do_reset)
        foreach (var ${paths})
            unet(${var} CACHE)
        endforeach()
    endif()
endfunction()

# Macro that handles looking for packages and installing them in the right
# place if missing. It uses specially crafted modules (in the packages directory)
# containing directives that specify how to find and install said packages.
#
# NOTE: We use a macro because find_package() creates variables such as:
# ${package}_FOUND cached and would be unavailable if created inside a function.
macro(gateau_find_package name)
    set(bool_options IN_SOURCE NO_EXTRACT NO_PATCH NO_UPDATE NO_CONFIGURE NO_BUILD NO_INSTALL)
    set(mono_options GIT TAG URL MD5 SOURCE_SUBDIR)
    set(multi_options CMAKE_CACHE_ARGS CMAKE_ARGS PATCH_COMMAND UPDATE_COMMAND CONFIGURE_COMMAND BUILD_COMMAND INSTALL_COMMAND)
    cmake_parse_arguments(_O
        "${bool_options};OPTIONAL;BUILD_ONLY_DEP;UPDATE_DEP"
        "${mono_options};SINGLE_HEADER"
        "${multi_options}"
        ${ARGN}
    )

    # Try to find the dependency package file that contains instructions on how
    # to find and install a package. Then we source it.
    # Also handle the single header special-case
    _gateau_prepare_dep_package_file(${name} "${_O_SINGLE_HEADER}" package_file)
    if (EXISTS "${package_file}")
        include("${package_file}")
    endif()

    # if a dep was uninstalled on changed for some reason, we try to reset its status
    _gateau_reset_find_package(${name})

    # try to find the dependency
    _gateau_find_dep_wrapper(${name} ${_O_UNPARSED_ARGUMENTS} QUIET)

    set(just_installed FALSE)

    # not found, we will try to install it and search again
    if (NOT ${name}_FOUND AND NOT _O_OPTIONAL)
        # build option list from arguments
        gateau_rebuild_parsed(_O "${bool_options}" "${mono_options}" "${multi_options}" _opts)

        # perform installation
        _gateau_install_dep_wrapper(${name} ${_opts})

        # search again
        _gateau_find_dep_wrapper(${name} ${_O_UNPARSED_ARGUMENTS} REQUIRED)

        if (NOT ${name}_FOUND)
            message(FATAL_ERROR "Installation of package '${name}' failed.")
        endif()

        set(just_installed TRUE)
    endif()

    # configure custom targets for this dep if some are available
    if (${name}_FOUND)
        _gateau_configure_dep_targets(${name} ${just_installed})
    endif()

    # update the dep if asked
    if (${name}_FOUND AND NOT just_installed)
        gateau_get(UPDATE_DEPS _update_deps)
        if (_O_UPDATE_DEP OR _update_deps)
            _gateau_maybe_update_dep(${name})
        endif()
        unset(_update_deps)
    endif()

    # Register this package as a required dependency for software that will use
    # our project, unless it has been marked as a build-only dep.
    if (${name}_FOUND AND NOT _O_BUILD_ONLY_DEP)
        _gateau_register_dep(${name} "${package_file}" ${_O_UNPARSED_ARGUMENTS})
    endif()

    # We are a macro, unset everything
    gateau_cleanup_parsed(_O "${bool_options}" "${mono_options}" "${multi_options}")

    unset(just_installed)
    unset(bool_options)
    unset(mono_options)
    unset(multi_options)
    unset(_opts)
    unset(package_file)
endmacro()
