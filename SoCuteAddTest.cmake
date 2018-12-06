# This module encapsulates add_test in order to ensure proper execution with
# Windows and linux-mingw plateforms

# Extracts the library paths needed by the mingw compiler
function(socute_mingw_library_paths out)
    # determine library path for later execution of executables with wine
    execute_process(
        COMMAND ${CMAKE_CXX_COMPILER} -print-search-dirs
        OUTPUT_VARIABLE COMPILER_LIBRARIES
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    string(FIND "${COMPILER_LIBRARIES}" "libraries: =" POS)
    string(SUBSTRING "${COMPILER_LIBRARIES}" ${POS} -1 COMPILER_LIBRARIES)
    string(REGEX REPLACE "libraries: =([^ ]*)" "\\1" COMPILER_LIBRARIES "${COMPILER_LIBRARIES}")
    string(REPLACE ":" "\;" COMPILER_LIBRARIES "${COMPILER_LIBRARIES}")
    set(${out} ${COMPILER_LIBRARIES} PARENT_SCOPE)
endfunction()

# converts a list of unix paths to a list of wine paths
function(socute_to_wine_paths path_list out)
    execute_process(
        COMMAND winepath -w ${path_list}
        OUTPUT_VARIABLE RESULT
    )
    string(REPLACE "\n" "\;" RESULT ${RESULT})
    set(${out} ${RESULT} PARENT_SCOPE)
endfunction()

# converts a list of unix paths to a list of windows paths
function(socute_to_win_paths path_list out)
    foreach(p ${path_list})
        file(TO_NATIVE_PATH "${p}" res)
        list(APPEND out_list "${res}")
    endforeach()

    set(${out} ${out_list} PARENT_SCOPE)
endfunction()

# Obtain a list of library directories needed to execute the tests on windows.
# Needed because of the lack of rpath.
function(socute_win_library_paths out)
    socute_mingw_library_paths(paths)
    foreach(prefix ${CMAKE_PREFIX_PATH})
        foreach(dir bin lib lib64)
            set(path "${prefix}/${dir}")
            if (IS_DIRECTORY ${path})
                list(APPEND paths ${path})
            endif()
        endforeach()
    endforeach()
    set(${out} ${paths} PARENT_SCOPE)
endfunction()

macro(socute_add_test target)
    if (CMAKE_SYSTEM_NAME STREQUAL Windows)
        socute_win_library_paths(lib_paths)

        # we need to use wine pathes
        if (CROSSCOMPILING_EMULATOR)
            socute_to_wine_paths("${lib_paths}" win_paths)
        else()
            socute_to_win_paths(${lib_paths} win_paths)
        endif()

        add_test(
            NAME ${target}
            COMMAND ${CROSSCOMPILING_EMULATOR} cmd /c "PATH=${win_paths};%PATH%" \\& ${target}${CMAKE_EXECUTABLE_SUFFIX}
            WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
        )
    else()
        add_test(${target} ${target})
    endif()
endmacro()
