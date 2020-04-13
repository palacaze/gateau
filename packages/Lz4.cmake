set(Lz4_URL "https://github.com/lz4/lz4/archive/v1.9.2.tar.gz")
set(Lz4_MD5 "3898c56c82fb3d9455aefd48db48eaad")
set(Lz4_SOURCE_SUBDIR "contrib/cmake_unofficial")

macro(Lz4_find name)
    include(FindPackageHandleStandardArgs)

    # remove from the cathe variables found for files not existing anymore
    if (DEFINED ${name}_INCLUDE_DIR AND NOT EXISTS "${${name}_INCLUDE_DIR}/lz4.h")
        unset(${name}_INCLUDE_DIR CACHE)
    endif()
    if (DEFINED ${name}_LIBRARY AND NOT EXISTS "${${name}_LIBRARY}")
        unset(${name}_LIBRARIES CACHE)
    endif()

    find_path(${name}_INCLUDE_DIR NAMES lz4.h)
    find_library(${name}_LIBRARY NAMES lz4)

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

