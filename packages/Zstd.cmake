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

    find_path(${name}_INCLUDE_DIRS NAMES zstd.h)
    find_library(${name}_LIBRARIES NAMES zstd)

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
