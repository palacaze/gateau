# A wrapper over ExternalProject_Add that simplifies its use

include(ExternalProject)
include(SoCuteParseArguments)

# Create the directories needed to install the dependency dep
function(_socute_prepare_external_dirs dep)
    socute_external_root(d)
    socute_create_dir("${d}")
    socute_external_download_dir("${dep}" d)
    socute_create_dir("${d}")
    socute_external_source_dir("${dep}" d)
    socute_create_dir("${d}")
    socute_external_install_dir("${dep}" d)
    socute_create_dir("${d}")

    # several locations are used by externalproject for the build
    socute_external_build_dir("${dep}" bd)
    set (_dirs
        "${bd}/build"
        "${bd}/stamp"
        "${bd}/tmp"
        "${bd}/ext/build")

    foreach(dir ${_dirs})
        socute_create_dir("${dir}")
    endforeach()
endfunction()

# Function that simplifies working with ExternalProject_Add
# It set an external project up using the supplied available information and
# executes it in order to install the dependency immediately.
# The list of recognized arguments is in the list of options at the begining
# of the function below, they mostly match the names and meaning of the one
# accepted by ExternalProject_add.
# The arguments used to configure the external project are retrieved from two
# sources: the arguments supplied to the function, as well as any variable in
# scope that as the form ${dep}_OPTION_NAME, where OPTION_NAME is a variable
# name from the 3 lists below.
# Unrecognized arguments will be passed as-is to ExternalProject_Add.
function(socute_install_dependency dep)
    set(bool_options IN_SOURCE NO_EXTRACT NO_CONFIGURE NO_PATCH NO_UPDATE NO_BUILD NO_INSTALL)
    set(mono_options GIT TAG MD5 SOURCE_SUBDIR)
    set(multi_options URL CMAKE_ARGS PATCH_COMMAND UPDATE_COMMAND CONFIGURE_COMMAND BUILD_COMMAND INSTALL_COMMAND)

    # parse arguments supplied to the function and account for default arguments
    # stored in variables whose names are prefixed with "${dep}_"
    socute_parse_arguments(SID ${dep} "${bool_options}" "${mono_options}" "${multi_options}" ${ARGN})

    # sanity checks, we need a few options and avoid ambiguities
    if (NOT SID_GIT AND NOT SID_URL)
        message(FATAL_ERROR "Missing source URL for dependency ${dep}")
    endif()

    # A package can either use an archive or a git repo, we ensure only one
    # of them is set
    if (SID_GIT AND SID_URL)
        if (${dep}_GIT)
            unset(SID_GIT)
            unset(SID_TAG)
        elseif(${dep}_URL)
            unset(SID_URL)
            unset(SID_MD5)
        endif()
    endif()

    # default to master branch if none supplied
    if (SID_GIT AND NOT SID_TAG)
        set(SID_TAG "master")
    endif()

    # where stuff will be built and installed: per package dirs
    socute_external_root(external_root)
    socute_external_download_dir("${dep}" download_dir)
    socute_external_source_dir("${dep}" source_dir)
    socute_external_build_dir("${dep}" build_dir)
    socute_external_install_dir("${dep}" install_prefix)

    # A reasonable assumption is that if we stepped in this function the package
    # is currently not installed or its version is not compatible with what is
    # required. The safe bet is to reinstall it from scratch. For git archives,
    # the provided git tag will be used and the install will be reissued no matter
    # what (the prefix content will be deleted beforehand.
    if (SID_URL)
        file(REMOVE_RECURSE "${build_dir}")
    endif()

    # We also delete the prefix dir to avoid stale files
    file(REMOVE_RECURSE "${install_prefix}")

    # ensure the needed working directories exist
    _socute_prepare_external_dirs(${dep})

    message(STATUS "Dependency ${dep} will be built in ${build_dir}")
    message(STATUS "Dependency ${dep} will be installed in ${install_prefix}")

    # some cmake "cached" arguments that we wish to pass to ExternalProject_Add
    set(cache_args
        "-DBUILD_SHARED_LIBS:BOOL=${BUILD_SHARED_LIBS}"
        "-DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}"
        "-DCMAKE_INSTALL_PREFIX:PATH=${install_prefix}"
        "-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY:BOOL=ON"
        "-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY:BOOL=ON"
        "-DCMAKE_FIND_USE_PACKAGE_REGISTRY:BOOL=OFF"
        "-DSOCUTE_EXTERNAL_ROOT:PATH=${external_root}"
    )

    # build type
    socute_external_build_type(build_type)
    if (GENERATOR_IS_MULTI_CONFIG)
        list(APPEND cache_args "-DCMAKE_CONFIGURATION_TYPES:STRING=${build_type}")
    else()
        list(APPEND cache_args "-DCMAKE_BUILD_TYPE:STRING=${build_type}")
    endif()

    # pass compiler or toolchain file
    if (CMAKE_TOOLCHAIN_FILE)
        list(APPEND cache_args "-DCMAKE_TOOLCHAIN_FILE:FILEPATH=${CMAKE_TOOLCHAIN_FILE}")
        list(APPEND cache_args "-DSOCUTE_TOOLCHAIN_COMPILER_VERSION:STRING=${SOCUTE_TOOLCHAIN_COMPILER_VERSION}")
    else()
        list(APPEND cache_args "-DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}")
        list(APPEND cache_args "-DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}")
    endif()

    set(project_vars
        PREFIX "${build_dir}"
        STAMP_DIR "${build_dir}/stamp"
        TMP_DIR "${build_dir}/tmp"
        DOWNLOAD_DIR "${download_dir}"
        SOURCE_DIR "${source_dir}"
        INSTALL_DIR "${install_prefix}"
        CMAKE_CACHE_ARGS ${cache_args}
    )

    # Work offline ?
    list(APPEND project_vars UPDATE_DISCONNECTED ${SOCUTE_OFFLINE})

    # Archive package
    if (SID_URL)
        list(APPEND project_vars URL ${SID_URL})
         message(STATUS "${dep} will download file ${SID_URL}")
    endif()

    if (SID_MD5)
        list(APPEND project_vars URL_MD5 ${SID_MD5})
    endif()

    # Git package, the version is used as a tag
    if (SID_GIT)
        list(APPEND project_vars GIT_REPOSITORY ${SID_GIT})
        list(APPEND project_vars GIT_SHALLOW 1)
        list(APPEND project_vars GIT_TAG ${SID_TAG})

        message(STATUS "${dep} will clone repo ${SID_GIT} branch ${SID_TAG}")
    endif()

    if (SID_IN_SOURCE)
        list(APPEND project_vars BUILD_IN_SOURCE 1)
    else()
        list(APPEND project_vars BINARY_DIR "${build_dir}/build")
    endif()

    if (SID_NO_EXTRACT)
        list(APPEND project_vars DOWNLOAD_NO_EXTRACT 1)
    endif()

    if (SID_SOURCE_SUBDIR)
        list(APPEND project_vars SOURCE_SUBDIR "${SID_SOURCE_SUBDIR}")
    endif()

    foreach(step UPDATE PATCH CONFIGURE BUILD INSTALL)
        if (SID_NO_${step})
            list(APPEND project_vars ${step}_COMMAND "")
        endif()
        if (SID_${step}_COMMAND)
            list(APPEND project_vars ${step}_COMMAND "${SID_${step}_COMMAND}")
        endif()
    endforeach()

    if (SID_CMAKE_ARGS)
        list(APPEND project_vars CMAKE_ARGS ${SID_CMAKE_ARGS})
    endif()

    if (SID_UNPARSED_ARGUMENTS)
        list(APPEND project_vars ${SID_UNPARSED_ARGUMENTS})
    endif()

    # We setup a mock project and execute it in a process to force immediate
    # installation of the package. ExternalProject_Add would defer installation
    # at build time instead and that would make using external dependencies for
    # the current project very difficult.
    set(ext_dir "${build_dir}/ext")

    #generate false dependency project
    set(ext_cmake_content "
        cmake_minimum_required(VERSION 3.8)
        project(dep)
        include(ExternalProject)
        ExternalProject_add(${dep} \"${project_vars}\")
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
endfunction()
