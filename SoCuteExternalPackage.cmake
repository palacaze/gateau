# A wrapper over ExternalProject_Add that simplifies its use

include(ExternalProject)

# Create the tree of directories needed to install a package
# - prefix      // where stuff will be installed
# - work        // work dir
#   - build     // build dir
#   - ext/build // dir where we execute a cmake file with ExternalProject_Add
# ${SOCUTE_EXTERNAL_ROOT}/download  // archive download, shared
# "{SOCUTE_EXTERNAL_ROOT}/src       // source dir, shared
function(socute_prepare_prefix ext_root root_dir)
    set (_dirs
        "${root_dir}/prefix"
        "${external_root}/download"
        "${external_root}/src"
        "${root_dir}/work/build"
        "${root_dir}/work/stamp"
        "${root_dir}/work/tmp"
        "${root_dir}/work/ext/build")

    foreach(dir ${_dirs})
        file(MAKE_DIRECTORY "${dir}")
        if (NOT EXISTS "${dir}")
            message(FATAL_ERROR "could not find or make directory ${dir}")
        endif()
    endforeach()
endfunction()

# Function that simplifies working with ExternalProject_Add
# Setup external project for a dependency to be built.
# Accepts optional arguments IN_SOURCE and NO_EXTRACT as well as NO_CONFIGURE,
# NO_BUILD and NO_INSTALL to disable those steps. Other unrecognized arguments
# will be passed as-is to ExternalProject_Add.
function(socute_external_package dep)
    set(options IN_SOURCE NO_EXTRACT NO_CONFIGURE NO_BUILD NO_INSTALL)
    cmake_parse_arguments(SEP "${options}" "" "" ${ARGN})

    socute_get_external_root(external_root)
    socute_get_install_root(install_root)

    # where stuff will really be installed: per package dir
    set(install_prefix "${install_root}/${dep}")

    # we need to import the module to get the appropriate variablese 2 places are possible
    set(module_path "${SOCUTE_CMAKE_MODULES_DIR}/packages/${dep}.cmake")
    if (NOT EXISTS "${module_path}")
        set(module_path "${CMAKE_BINARY_DIR}/gen-modules/${dep}.cmake")
    endif()

    if (EXISTS "${module_path}")
        include("${module_path}")
    else()
        message(SEND_ERROR "No description module for package ${dep}, skip installation.")
        return()
    endif()

    if (NOT DEFINED ${dep}_version)
        message(FATAL_ERROR "Missing version number for package ${dep}")
    endif()

    # A reasonable assumption is that if we stepped in this function the package
    # is currently not installed or its version is not compatible with what is
    # required. The safe bet is to reinstall it from scratch. For git archives,
    # the provided git tag will be used and the install will be reissued no matter
    # what (the prefix content will be deleted beforehand.
    set(work_dir "${install_prefix}/work")
    set(prefix_dir "${install_prefix}/prefix")
    set(version_file "${install_prefix}/.version")

    # Get current version number, if it exists
    if (EXISTS "${version_file}")
        file(READ "${version_file}" cur_version)
    endif()

    if (DEFINED ${dep}_url)
        # delete work dir
        file(REMOVE_RECURSE "${work_dir}")
    endif()

    # we delete the prefix dir to avoid stale files
    file(REMOVE_RECURSE "${prefix_dir}")

    message(STATUS "Dependency ${dep} will be built in ${prefix_dir}")

    # ensure the needed working directories exist
    socute_prepare_prefix("${external_root}" "${install_prefix}")

    # some cmake "cached" arguments that we wish to pass to ExternalProject_Add
    set(cache_args
        "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
        "-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}"
        "-DCMAKE_PREFIX_PATH:PATH=${CMAKE_PREFIX_PATH}"
        "-DCMAKE_INSTALL_PREFIX:PATH=${prefix_dir}"
        "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY:BOOL=ON"
        "-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY:BOOL=ON"
        "-DSOCUTE_EXTERNAL_ROOT:PATH=${external_root}"
    )

    # pass compiler or toolchain file
    if (CMAKE_TOOLCHAIN_FILE)
        list(APPEND cache_args "-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${CMAKE_TOOLCHAIN_FILE}")
        list(APPEND cache_args "-DSOCUTE_TOOLCHAIN_COMPILER_VERSION:STRING=${SOCUTE_TOOLCHAIN_COMPILER_VERSION}")
    else()
        list(APPEND cache_args "-DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}")
        list(APPEND cache_args "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}")
    endif()

    set(project_vars
        PREFIX "${work_dir}"
        STAMP_DIR "${work_dir}/stamp"
        TMP_DIR "${work_dir}/tmp"
        DOWNLOAD_DIR "${external_root}/download/${dep}"
        SOURCE_DIR "${external_root}/src/${dep}"
        INSTALL_DIR "${prefix_dir}"
        CMAKE_CACHE_ARGS ${cache_args}
    )

    # Work offline ?
    list(APPEND project_vars UPDATE_DISCONNECTED ${SOCUTE_OFFLINE})

    # Archive package
    if (DEFINED ${dep}_url)
        list(APPEND project_vars URL ${${dep}_url})
         message(STATUS "${dep} will download file ${${dep}_url}")
    endif()

    if (DEFINED ${dep}_md5)
        list(APPEND project_vars URL_MD5 ${${dep}_md5})
    endif()

    # Git package, the version is used as a tag
    if (DEFINED ${dep}_git)
        list(APPEND project_vars GIT_REPOSITORY ${${dep}_git})
        list(APPEND project_vars GIT_SHALLOW 1)
        list(APPEND project_vars GIT_TAG ${${dep}_version})

        message(STATUS "${dep} will clone repo ${${dep}_git}")
    endif()

    if (SEP_IN_SOURCE)
        list(APPEND project_vars BUILD_IN_SOURCE 1)
    else()
        list(APPEND project_vars BINARY_DIR "${work_dir}/build/${dep}")
    endif()

    if (SEP_NO_EXTRACT)
        list(APPEND project_vars DOWNLOAD_NO_EXTRACT 1)
    endif()

    foreach(step CONFIGURE BUILD INSTALL)
        if (SEP_NO_${step})
            list(APPEND project_vars ${step}_COMMAND "")
        endif()
    endforeach()

    if (SEP_UNPARSED_ARGUMENTS)
        list(APPEND project_vars ${SEP_UNPARSED_ARGUMENTS})
    endif()

    # We setup a mock project and execute it in a process to force immediate
    # installation of the package. ExternalProject_Add would defer installation
    # at build time instead and that would make using external dependencies for
    # the current project very difficult.

    set(ext_dir ${work_dir}/ext)
    file(MAKE_DIRECTORY ${ext_dir}/build)

    #generate false dependency project
    set(ext_cmake_content "
        cmake_minimum_required(VERSION 3.8)
        include(ExternalProject)
        ExternalProject_add(${dep} ${project_vars})
        add_custom_target(trigger_${dep})
        add_dependencies(trigger_${dep} ${dep})
    ")

    file(WRITE "${ext_dir}/CMakeLists.txt" "${ext_cmake_content}")

    # we must set a toochain file if the project needs one
    if (CMAKE_TOOLCHAIN_FILE)
        set(toolchain_cmd -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE})
    endif()

    # execute installation process
    execute_process(
        COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" ${toolchain_cmd} ..
        WORKING_DIRECTORY "${ext_dir}/build"
    )
    execute_process(
        COMMAND ${CMAKE_COMMAND} --build .
        WORKING_DIRECTORY "${ext_dir}/build"
    )

    # record version
    file(WRITE "${version_file}" "${${dep}_version}")
endfunction()
