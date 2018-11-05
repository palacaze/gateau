set(RapidJSON_version "1.1.0")
set(RapidJSON_url "https://github.com/Tencent/rapidjson/archive/v${RapidJSON_version}.tar.gz")
set(RapidJSON_md5 "badd12c511e081fec6c89c43a7027bce")

include(SoCuteExternalPackage)

# RapidJSON cmake find module does not export targets in correctly, so we do
# this ourselves
macro(pkg_find)
    find_package(RapidJSON ${RapidJSON_version} ${ARGN})

    if (RapidJSON_FOUND AND NOT TARGET RapidJSON::RapidJSON)
        add_library(RapidJSON::RapidJSON INTERFACE IMPORTED)
        set_target_properties(RapidJSON::RapidJSON PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${RAPIDJSON_INCLUDE_DIRS}"
        )
    endif()
endmacro()

macro(pkg_install)
    socute_external_package(RapidJSON
        CMAKE_ARGS "-DRAPIDJSON_BUILD_DOC=OFF"
                   "-DRAPIDJSON_BUILD_EXAMPLES=OFF"
                   "-DRAPIDJSON_BUILD_TESTS=OFF"
                   "-DRAPIDJSON_BUILD_THIRDPARTY_GTEST=OFF"
    )
endmacro()
