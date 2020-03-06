set(Lz4_URL "https://github.com/lz4/lz4/archive/v1.9.2.tar.gz")
set(Lz4_MD5 "3898c56c82fb3d9455aefd48db48eaad")
set(Lz4_SOURCE_SUBDIR "contrib/cmake_unofficial")

macro(Lz4_find name)
    include(FindPackageHandleStandardArgs)

    find_path(${name}_INCLUDE_DIRS NAMES lz4.h)
    find_library(${name}_LIBRARIES NAMES lz4)

    find_package_handle_standard_args(
        ${name} DEFAULT_MSG ${name}_LIBRARIES ${name}_INCLUDE_DIRS)

    mark_as_advanced(${name}_LIBRARIES ${name}_INCLUDE_DIRS)

    if(${name}_FOUND AND NOT TARGET ${name}::${name})
        add_library(${name}::${name} UNKNOWN IMPORTED)
        set_target_properties(${name}::${name} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${${name}_INCLUDE_DIRS}"
            IMPORTED_LOCATION "${${name}_LIBRARIES}"
        )
    endif()
endmacro()

