include(GNUInstallDirs)
set(gRPC_GIT "https://github.com/grpc/grpc.git")
set(gRPC_TAG "origin/v1.28.x")
set(gRPC_GIT_CONFIG submodule.third_party/boringssl-with-bazel.shallow=true)
set(gRPC_CMAKE_ARGS
    -DgRPC_INSTALL_LIBDIR=${CMAKE_INSTALL_LIBDIR}
    -DgRPC_INSTALL_CMAKEDIR=${CMAKE_INSTALL_LIBDIR}/cmake/grpc
    -DgRPC_BUILD_TESTS=OFF
    -DgRPC_BUILD_CSHARP_EXT=OFF
    -DgRPC_BUILD_GRPC_CSHARP_PLUGIN=OFF
    -DgRPC_BUILD_GRPC_NODE_PLUGIN=OFF
    -DgRPC_BUILD_GRPC_OBJECTIVE_C_PLUGIN=OFF
    -DgRPC_BUILD_GRPC_PHP_PLUGIN=OFF
    -DgRPC_BUILD_GRPC_PYTHON_PLUGIN=OFF
    -DgRPC_BUILD_GRPC_RUBY_PLUGIN=OFF
)

macro(gRPC_find name)
    find_package(Protobuf CONFIG)
    find_package(${name} CONFIG ${ARGN})
endmacro()


# Helper function that generates the protobuf stubs from a .proto file and adds
# the resulting files to target
function(gateau_add_protobuf target)
    set(_include_path -I "${CMAKE_CURRENT_SOURCE_DIR}")

    # add each proto file path to the include dirs
    foreach(proto ${ARGN})
        get_filename_component(abs_proto "${proto}" ABSOLUTE)
        get_filename_component(abs_path "${abs_proto}" PATH)
        if (NOT abs_proto IN_LIST _include_path)
            list(APPEND _include_path -I "${ABS_PATH}")
        endif()
    endforeach()

    set(_out_dir "${CMAKE_CURRENT_BINARY_DIR}")
    file(MAKE_DIRECTORY "${_out_dir}")

    # get the list of proto files added to the target sources
    set(_protos ${ARGN})
    get_target_property(_source_list ${target} SOURCES)
        foreach(_file ${_source_list})
        if(_file MATCHES "proto$")
            list(APPEND _protos ${_file})
        endif()
    endforeach()

    # generate stubs for every proto file
    foreach(_proto ${_protos})
        get_filename_component(_abs_file "${_proto}" ABSOLUTE)
        get_filename_component(_abs_dir "${_abs_file}" DIRECTORY)
        get_filename_component(_basename "${_proto}" NAME_WE)
        file(RELATIVE_PATH _rel_dir "${CMAKE_CURRENT_SOURCE_DIR}" "${_abs_dir}")

        set(src "${CMAKE_CURRENT_BINARY_DIR}/${_rel_dir}/${_basename}.pb.cc")
        set(hdr "${CMAKE_CURRENT_BINARY_DIR}/${_rel_dir}/${_basename}.pb.h")
        list(APPEND srcs "${src}")
        list(APPEND hdrs "${hdr}")

        add_custom_command(
            OUTPUT "${src}" "${hdr}"
            COMMAND protobuf::protoc
            ARGS --cpp_out=${_out_dir} ${_include_path} "${_abs_file}"
            DEPENDS "${_abs_file}" protobuf::protoc
            COMMENT "Running C++ protobuf compiler on ${_proto}"
            VERBATIM
        )
    endforeach()

    # append protobuf libs
    set(_proto_libs)
    get_target_property(_libs ${target} LINK_LIBRARIES)
    if (NOT protobuf::libprotobuf IN_LIST _libs)
        set(_proto_libs LINK_LIBRARIES protobuf::libprotobuf)
    endif()

    # annoying warning in gcc
    if (CMAKE_CXX_COMPILER MATCHES "Clang" OR CMAKE_COMPILER_IS_GNUCC)
        set_source_files_properties(${srcs} ${hdrs} PROPERTIES
            COMPILE_OPTIONS -Wno-array-bounds
        )
    endif()

    # add the generated files to the target sources
    gateau_extend_target(${target} SOURCES ${srcs} HEADERS ${hdrs} ${_proto_libs})
endfunction()

# Helper function that generates the grpc and protobuf stubs from a .proto file
# and adds the resulting files to target (A call to gateau_add_protobuf is not
# needed)
function(gateau_add_grpc target)
    # add protobuf data too
    gateau_add_protobuf(${target} ${ARGN})

    set(_include_path -I "${CMAKE_CURRENT_SOURCE_DIR}")

    # add each proto file path to the include dirs
    foreach(proto ${ARGN})
        get_filename_component(abs_proto "${proto}" ABSOLUTE)
        get_filename_component(abs_path "${abs_proto}" PATH)
        if (NOT abs_proto IN_LIST _include_path)
            list(APPEND _include_path -I "${ABS_PATH}")
        endif()
    endforeach()

    set(_out_dir "${CMAKE_CURRENT_BINARY_DIR}")
    file(MAKE_DIRECTORY "${_out_dir}")

    # get the list of proto files added to the target sources
    set(_protos ${ARGN})
    get_target_property(_source_list ${target} SOURCES)
        foreach(_file ${_source_list})
        if(_file MATCHES "proto$")
            list(APPEND _protos ${_file})
        endif()
    endforeach()

    # generate stubs for every proto file
    foreach(_proto ${_protos})
        get_filename_component(_abs_file "${_proto}" ABSOLUTE)
        get_filename_component(_abs_dir "${_abs_file}" DIRECTORY)
        get_filename_component(_basename "${_proto}" NAME_WE)
        file(RELATIVE_PATH _rel_dir "${CMAKE_CURRENT_SOURCE_DIR}" "${_abs_dir}")

        set(src "${CMAKE_CURRENT_BINARY_DIR}/${_rel_dir}/${_basename}.grpc.pb.cc")
        set(hdr "${CMAKE_CURRENT_BINARY_DIR}/${_rel_dir}/${_basename}.grpc.pb.h")
        list(APPEND srcs "${src}")
        list(APPEND hdrs "${hdr}")

        add_custom_command(
            OUTPUT "${src}" "${hdr}"
            COMMAND protobuf::protoc
            ARGS --grpc_out=${_out_dir}
                 ${_include_path}
                 --plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>
                 "${_abs_file}"
            DEPENDS "${_abs_file}" gRPC::grpc_cpp_plugin protobuf::protoc
            COMMENT "Running C++ gRPC compiler on ${_proto}"
            VERBATIM
        )
    endforeach()

    # append grpc libs
    set(_grpc_libs)
    get_target_property(_libs ${target} LINK_LIBRARIES)
    foreach(_grpc_lib gRPC::grpc++ gRPC::grpc++_reflection)
        if (NOT _grpc_lib IN_LIST _libs)
            list(APPEND _grpc_libs LINK_LIBRARIES ${_grpc_lib})
        endif()
    endforeach()

    # add the generated files to the target sources
    gateau_extend_target(${target} SOURCES ${srcs} HEADERS ${hdrs} ${_grpc_libs})
endfunction()
