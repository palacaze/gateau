# Same as cmake_parse_arguments, with additional handling of default arguments values
# For any option/argument name NAME and default prefix name def, the variable
# named ${def}_NAME will be used as default value if it exists
function(socute_parse_arguments prefix def_prefix _optionNames _singleArgNames _multiArgNames)
    # first set all result variables to empty
    foreach(arg_name ${_singleArgNames} ${_multiArgNames})
        set(${prefix}_${arg_name})
    endforeach()

    foreach(option ${_optionNames})
        set(${prefix}_${option} FALSE)
    endforeach()

    # set to default value if available
    foreach(arg_name ${_optionNames} ${_singleArgNames} ${_multiArgNames})
        if (DEFINED ${def_prefix}_${arg_name})
            set(${prefix}_${arg_name} ${${def_prefix}_${arg_name}})
        endif()
    endforeach()

    set(${prefix}_UNPARSED_ARGUMENTS)
    set(insideValues FALSE)
    set(currentArgName)

    # now iterate over all arguments and fill the result variables
    foreach(currentArg ${ARGN})
        list(FIND _optionNames "${currentArg}" optionIndex)
        list(FIND _singleArgNames "${currentArg}" singleArgIndex)
        list(FIND _multiArgNames "${currentArg}" multiArgIndex)

        if(${optionIndex} EQUAL -1  AND  ${singleArgIndex} EQUAL -1  AND  ${multiArgIndex} EQUAL -1)
            if(insideValues)
                if("${insideValues}" STREQUAL "SINGLE")
                    set(${prefix}_${currentArgName} ${currentArg})
                    set(insideValues FALSE)
                elseif("${insideValues}" STREQUAL "MULTI")
                    list(APPEND ${prefix}_${currentArgName} ${currentArg})
                endif()
            else()
                list(APPEND ${prefix}_UNPARSED_ARGUMENTS ${currentArg})
            endif()
        else()
            if(NOT ${optionIndex} EQUAL -1)
                set(${prefix}_${currentArg} TRUE)
                set(insideValues FALSE)
            elseif(NOT ${singleArgIndex} EQUAL -1)
                set(currentArgName ${currentArg})
                set(${prefix}_${currentArgName})
                set(insideValues "SINGLE")
            elseif(NOT ${multiArgIndex} EQUAL -1)
                set(currentArgName ${currentArg})
                set(${prefix}_${currentArgName})
                set(insideValues "MULTI")
            endif()
        endif()
    endforeach()

    # propagate the result variables to the caller:
    foreach(arg_name ${_singleArgNames} ${_multiArgNames} ${_optionNames})
        set(${prefix}_${arg_name} ${${prefix}_${arg_name}} PARENT_SCOPE)
    endforeach()

    set(${prefix}_UNPARSED_ARGUMENTS ${${prefix}_UNPARSED_ARGUMENTS} PARENT_SCOPE)
endfunction()
