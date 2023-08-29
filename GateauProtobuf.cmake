# Utilities to simplify usage of Protobuf and gRPC in cmake projects

# Helper function that calls protobuf's protoc code generator from .proto files
# and adds the resulting files to target.
function(gateau_protoc target)
    set(mono_options
        HEADER_EXT          # Header file extension, leading dot excluded
        SOURCE_EXT          # Source file extension, leading dot excluded
        COMMENT             # Command comment
        OUT_OPT             # Name of the protoc option which sets the output directory
        PLUGIN_OPT          # Name of the plugin option: --plugin=${PLUGIN_OPT}=...
        PLUGIN_TARGET       # Name of the cmake target holding the plugin
    )
    set(multi_options
        PROTO               # List of proto files to process
        PROTO_DIRECTORIES   # List of proto files include directories
        LINK_LIBRARIES      # additional libraries to link the target with
    )
    cmake_parse_arguments(_A "" "${mono_options}" "${multi_options}" ${ARGN})

    set(_out_dir "${CMAKE_CURRENT_BINARY_DIR}")
    file(MAKE_DIRECTORY "${_out_dir}")

    macro(maybe_set _opt _val)
        if (NOT _A_${_opt})
            set(_A_${_opt} "${_val}")
        endif()
    endmacro()

    maybe_set(HEADER_EXT "pb.h")
    maybe_set(SOURCE_EXT "pb.cc")
    maybe_set(COMMENT "Running C++ protobuf compiler")
    maybe_set(OUT_OPT "cpp_out")
    maybe_set(LINK_LIBRARIES protobuf::libprotobuf)

    # Build a list of proto directories, those are used as
    # protoc include directories
    foreach (_incl ${_A_PROTO_DIRECTORIES})
        list(APPEND _include_path -I "${_incl}")
    endforeach()

    # add each proto file path to the include directories
    foreach(proto ${_A_PROTO})
        get_filename_component(_abs_proto "${proto}" ABSOLUTE)
        get_filename_component(_abs_path "${_abs_proto}" PATH)
        if (NOT _abs_proto IN_LIST _include_path)
            list(APPEND _include_path -I "${_abs_path}")
        endif()
    endforeach()

    # get the list of proto files added to the target sources
    set(_protos ${_A_PROTO})
    get_target_property(_source_list ${target} SOURCES)
    foreach(_file ${_source_list})
        if(_file MATCHES "proto$")
            list(APPEND _protos ${_file})
        endif()
    endforeach()

    # Plugin settings if one is used
    if (_A_PLUGIN_OPT AND _A_PLUGIN_TARGET)
        set(_plugin "--plugin=${_A_PLUGIN_OPT}=$<TARGET_FILE:${_A_PLUGIN_TARGET}>")
    endif()

    # generate stubs for every proto file
    foreach(_proto ${_protos})
        get_filename_component(_proto_path "${_proto}" ABSOLUTE)
        get_filename_component(_abs_dir "${_proto_path}" DIRECTORY)
        get_filename_component(_basename "${_proto}" NAME_WE)
        file(RELATIVE_PATH _rel_dir "${CMAKE_CURRENT_SOURCE_DIR}" "${_abs_dir}")

        set(src "${CMAKE_CURRENT_BINARY_DIR}/${_rel_dir}/${_basename}.${_A_SOURCE_EXT}")
        set(hdr "${CMAKE_CURRENT_BINARY_DIR}/${_rel_dir}/${_basename}.${_A_HEADER_EXT}")
        list(APPEND srcs "${src}")
        list(APPEND hdrs "${hdr}")

        add_custom_command(
            OUTPUT "${src}" "${hdr}"
            COMMAND protobuf::protoc
            ARGS --${_A_OUT_OPT}=${_out_dir}
                 ${_plugin}
                 ${_include_path}
                 "${_proto_path}"
            DEPENDS "${_proto_path}" protobuf::protoc ${_A_PLUGIN_TARGET}
            COMMENT "${_A_COMMENT} on ${_proto}"
            VERBATIM
        )
    endforeach()

    # append link libraries
    set(_link_libs)
    get_target_property(_libs ${target} LINK_LIBRARIES)
    foreach(_lib ${_A_LINK_LIBRARIES})
        if (NOT _lib IN_LIST _libs)
            list(APPEND _link_libs ${_lib})
        endif()
    endforeach()

    # Disable warnings for generated files
    if (CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_COMPILER_IS_GNUCC)
        set_source_files_properties(${srcs} ${hdrs} PROPERTIES
            COMPILE_OPTIONS -w
        )
    endif()

    # add the generated files to the target sources
    gateau_extend_target(${target}
        SYSTEM
        SOURCES ${srcs}
        HEADERS ${hdrs}
        LINK_LIBRARIES PUBLIC ${_link_libs}
    )
endfunction()


# Helper function that generates the C++ protobuf stubs from a .proto file and adds
# the resulting files to target
function(gateau_generate_protobuf target)
    gateau_protoc(${target} PROTO ${ARGN})
endfunction()

# Helper function that generates the grpc and protobuf C++ stubs from a .proto file
# and adds the resulting files to target (A call to gateau_generate_protobuf is not
# needed)
function(gateau_generate_grpc target)
    gateau_generate_protobuf(${target} ${ARGN})
    gateau_protoc(${target}
        PROTO ${ARGN}
        HEADER_EXT "grpc.pb.h"
        SOURCE_EXT "grpc.pb.cc"
        COMMENT "Running C++ gRPC compiler"
        OUT_OPT "grpc_out"
        PLUGIN_OPT "protoc-gen-grpc"
        PLUGIN_TARGET gRPC::grpc_cpp_plugin
        LINK_LIBRARIES gRPC::grpc gRPC::grpc++ gRPC::grpc++_reflection
    )
endfunction()
