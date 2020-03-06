set(xxHash_URL "https://github.com/Cyan4973/xxHash/archive/v0.7.2.tar.gz")
set(xxHash_MD5 "4ed30cba38598deae52ec14a189f1b6e")
set(xxHash_SOURCE_SUBDIR "cmake_unofficial")
set(xxHash_CMAKE_ARGS -DXXHASH_BUILD_XXHSUM=OFF)

macro(xxHash_find name)
    find_package(${name} CONFIG ${ARGN})
endmacro()
