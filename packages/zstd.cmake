set(zstd_VERSION "1.5.0")
set(zstd_MD5 "a6eb7fb1f2c21fa80030a47993853e92")
set(zstd_URL "https://github.com/facebook/zstd/releases/download/v${zstd_VERSION}/zstd-${zstd_VERSION}.tar.gz")
set(zstd_CMAKE_ARGS
    -DZSTD_BUILD_PROGRAMS=OFF
    -DZSTD_LEGACY_SUPPORT=OFF
    -DZSTD_BUILD_SHARED=OFF
    -DZSTD_BUILD_STATIC=ON
)
set(zstd_SOURCE_SUBDIR "build/cmake")

