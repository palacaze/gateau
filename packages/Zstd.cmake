set(Zstd_VERSION "1.4.4")
set(Zstd_MD5 "532aa7b3a873e144bbbedd9c0ea87694")
set(Zstd_URL "https://github.com/facebook/zstd/archive/v${Zstd_VERSION}.tar.gz")
set(Zstd_CMAKE_ARGS
    -DZSTD_BUILD_PROGRAMS=OFF
    -DZSTD_LEGACY_SUPPORT=OFF
    -DZSTD_BUILD_SHARED=OFF
    -DZSTD_BUILD_STATIC=ON
)
set(Zstd_SOURCE_SUBDIR "build/cmake")

macro(Zstd_find name)
    include(FindPackageHandleStandardArgs)

    if (DEFINED ${name}_INCLUDE_DIR AND NOT EXISTS "${${name}_INCLUDE_DIR}/zstd.h")
        unset(${name}_INCLUDE_DIR CACHE)
    endif()
    if (DEFINED ${name}_LIBRARY AND NOT EXISTS "${${name}_LIBRARY}")
        unset(${name}_LIBRARY CACHE)
    endif()

    find_path(${name}_INCLUDE_DIR NAMES zstd.h)
    find_library(${name}_LIBRARY NAMES zstd)

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
