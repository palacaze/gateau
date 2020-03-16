set(RapidJSON_version "1.1.0")
set(RapidJSON_URL "https://github.com/Tencent/rapidjson/archive/v${RapidJSON_version}.tar.gz")
set(RapidJSON_MD5 "badd12c511e081fec6c89c43a7027bce")
set(RapidJSON_CMAKE_ARGS
    -DRAPIDJSON_BUILD_DOC=OFF
    -DRAPIDJSON_BUILD_EXAMPLES=OFF
    -DRAPIDJSON_BUILD_TESTS=OFF
    -DRAPIDJSON_BUILD_THIRDPARTY_GTEST=OFF
)

macro(RapidJSON_find name)
    find_package(RapidJSON ${RapidJSON_version} ${ARGN})

    # RapidJSON cmake find module does not export targets in correctly, so we do
    # this ourselves
    if (RapidJSON_FOUND AND NOT TARGET RapidJSON::RapidJSON)
        add_library(RapidJSON::RapidJSON INTERFACE IMPORTED)
        set_target_properties(RapidJSON::RapidJSON PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${RAPIDJSON_INCLUDE_DIRS}"
        )
    endif()
endmacro()
