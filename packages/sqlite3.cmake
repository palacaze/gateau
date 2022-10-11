set(sqlite3_SOURCE_SUBDIR "contrib/cmake_unofficial")

macro(sqlite3_find name)
    include(FindPackageHandleStandardArgs)

    # remove from the cathe variables found for files not existing anymore
    if (DEFINED ${name}_INCLUDE_DIR AND NOT EXISTS "${${name}_INCLUDE_DIR}/sqlite3.h")
        unset(${name}_INCLUDE_DIR CACHE)
    endif()
    if (DEFINED ${name}_LIBRARY AND NOT EXISTS "${${name}_LIBRARY}")
        unset(${name}_LIBRARY CACHE)
    endif()

    find_path(${name}_INCLUDE_DIR NAMES sqlite3.h)
    find_library(${name}_LIBRARY NAMES sqlite3)

    find_package_handle_standard_args(
        ${name} DEFAULT_MSG ${name}_LIBRARY ${name}_INCLUDE_DIR)

    mark_as_advanced(${name}_LIBRARY ${name}_INCLUDE_DIR)

    if(${name}_FOUND AND NOT TARGET ${name}::${name})
        add_library(${name}::${name} UNKNOWN IMPORTED)
        set_target_properties(${name}::${name} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${${name}_INCLUDE_DIR}"
            IMPORTED_LOCATION "${${name}_LIBRARY}"
        )
    endif()
endmacro()

