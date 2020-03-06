set(spdlog_VERSION "1.5.0")
set(spdlog_URL "https://github.com/gabime/spdlog/archive/v${spdlog_VERSION}.tar.gz")
set(spdlog_MD5 "a966eea01f81551527853d282896cb4d")
set(spdlog_CMAKE_ARGS
    -DSPDLOG_BUILD_BENCH=OFF
    -DSPDLOG_BUILD_EXAMPLE=OFF
    -DSPDLOG_FMT_EXTERNAL=ON
    -DSPDLOG_BUILD_SHARED=OFF
    -DSPDLOG_BUILD_TESTS=OFF
)
