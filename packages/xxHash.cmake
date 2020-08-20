set(xxHash_URL "https://github.com/Cyan4973/xxHash/archive/v0.8.0.tar.gz")
set(xxHash_MD5 "62310678857c30fcef4128f41f711f49")
set(xxHash_SOURCE_SUBDIR "cmake_unofficial")
set(xxHash_CMAKE_ARGS -DXXHASH_BUILD_XXHSUM=OFF)

macro(xxHash_find name)
    find_package(${name} CONFIG ${ARGN})
endmacro()
