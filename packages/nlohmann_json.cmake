set(nlohmann_json_VERSION "3.10.5")
set(nlohmann_json_URL "https://github.com/nlohmann/json/archive/refs/tags/v${nlohmann_json_VERSION}.tar.gz")
set(nlohmann_json_MD5 "5b946f7d892fa55eabec45e76a20286b")
set(nlohmann_json_CMAKE_ARGS
    -DJSON_BuildTests=OFF
    -DJSON_ImplicitConversions=ON
)
