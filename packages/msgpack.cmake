set(msgpack_VERSION "3.3.0")
set(msgpack_MD5 "bb8b3173b4bf864d96dac1532ecf781c")
set(msgpack_URL "https://github.com/msgpack/msgpack-c/archive/cpp-${msgpack_VERSION}.tar.gz")
set(msgpack_CMAKE_ARGS
    -DMSGPACK_BOOST=OFF
    -DMSGPACK_ENABLE_CXX=ON
    -DMSGPACK_ENABLE_STATIC=ON
    -DMSGPACK_BUILD_TESTS=OFF
    -DMSGPACK_BUILD_EXAMPLES=OFF
    -DMSGPACK_CXX11=ON
)
