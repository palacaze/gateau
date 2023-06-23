set(zstd_VERSION "1.5.2")
set(zstd_MD5 "072b10f71f5820c24761a65f31f43e73")
set(zstd_URL "https://github.com/facebook/zstd/releases/download/v${zstd_VERSION}/zstd-${zstd_VERSION}.tar.gz")

set(zstd_CMAKE_ARGS
    -DZSTD_BUILD_PROGRAMS=OFF
    -DZSTD_LEGACY_SUPPORT=OFF
    -DZSTD_BUILD_SHARED=ON
    -DZSTD_BUILD_STATIC=OFF
)
set(zstd_SOURCE_SUBDIR "build/cmake")

