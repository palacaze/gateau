# Same as cmake_parse_arguments, with additional handling of default arguments values
# For any option/argument name NAME and default prefix name def, the variable
# named ${def}_NAME will be used as default value if it exists
function(socute_parse_arguments prefix def_prefix _bool_names _single_names _multi_names)
    # first set all result variables to empty
    foreach(arg_name ${_single_names} ${_multi_names})
        set(${prefix}_${arg_name})
    endforeach()

    foreach(option ${_bool_names})
        set(${prefix}_${option} FALSE)
    endforeach()

    # set to default value if available
    foreach(arg_name ${_bool_names} ${_single_names} ${_multi_names})
        if (DEFINED ${def_prefix}_${arg_name})
            set(${prefix}_${arg_name} ${${def_prefix}_${arg_name}})
        endif()
    endforeach()

    set(${prefix}_UNPARSED_ARGUMENTS)
    set(inside_values FALSE)
    set(current_arg_name)

    # now iterate over all arguments and fill the result variables
    foreach(current_arg ${ARGN})
        list(FIND _bool_names "${current_arg}" option_idx)
        list(FIND _single_names "${current_arg}" single_idx)
        list(FIND _multi_names "${current_arg}" multi_idx)

        if(${option_idx} EQUAL -1  AND  ${single_idx} EQUAL -1  AND  ${multi_idx} EQUAL -1)
            if(inside_values)
                if("${inside_values}" STREQUAL "SINGLE")
                    set(${prefix}_${current_arg_name} ${current_arg})
                    set(inside_values FALSE)
                elseif("${inside_values}" STREQUAL "MULTI")
                    list(APPEND ${prefix}_${current_arg_name} ${current_arg})
                endif()
            else()
                list(APPEND ${prefix}_UNPARSED_ARGUMENTS ${current_arg})
            endif()
        else()
            if(NOT ${option_idx} EQUAL -1)
                set(${prefix}_${current_arg} TRUE)
                set(inside_values FALSE)
            elseif(NOT ${single_idx} EQUAL -1)
                set(current_arg_name ${current_arg})
                set(${prefix}_${current_arg_name})
                set(inside_values "SINGLE")
            elseif(NOT ${multi_idx} EQUAL -1)
                set(current_arg_name ${current_arg})
                set(${prefix}_${current_arg_name})
                set(inside_values "MULTI")
            endif()
        endif()
    endforeach()

    # propagate the result variables to the caller:
    foreach(arg_name ${_single_names} ${_multi_names} ${_bool_names})
        set(${prefix}_${arg_name} ${${prefix}_${arg_name}} PARENT_SCOPE)
    endforeach()

    set(${prefix}_UNPARSED_ARGUMENTS ${${prefix}_UNPARSED_ARGUMENTS} PARENT_SCOPE)
endfunction()

# cleanup created variables by a call to cmake_parse_arguments or socute_parse_arguments
# from a macro
function(socute_rebuild_parsed prefix _bool_names _single_names _multi_names out_list)
    set(_opts)
    foreach(_opt ${_bool_names})
        if (${prefix}_${_opt})
            list(APPEND _opts ${_opt})
        endif()
    endforeach()
    foreach(_opt ${_single_names} ${_multi_names})
        if (${prefix}_${_opt})
            list(APPEND _opts ${_opt} ${${prefix}_${_opt}})
        endif()
    endforeach()
    set(${out_list} "${_opts}" PARENT_SCOPE)
endfunction()

# cleanup created variables by a call to cmake_parse_arguments or socute_parse_arguments
# from a macro
function(socute_cleanup_parsed prefix _bool_names _single_names _multi_names)
    foreach(opt ${_bool_names} ${_single_names} ${_multi_names})
        unset(${prefix}_${opt} PARENT_SCOPE)
    endforeach()
    unset(${prefix}_UNPARSED_ARGUMENTS PARENT_SCOPE)
    unset(${prefix}_KEYWORDS_MISSING_VALUES PARENT_SCOPE)
endfunction()
