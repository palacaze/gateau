set(mongoc-1.0_URL "https://github.com/mongodb/mongo-c-driver/releases/download/1.16.0/mongo-c-driver-1.16.0.tar.gz")
set(mongoc-1.0_MD5 "b7af904b3ac094667d4c176c93925bfe")
set(mongoc-1.0_CMAKE_ARGS
    -DENABLE_EXAMPLES=OFF
    -DENABLE_ZSTD=OFF
    -DENABLE_ICU=OFF
    -DENABLE_BSON=ON
    -DENABLE_MONGOC=ON
    -DENABLE_SASL=OFF
    -DENABLE_STATIC=ON
    -DENABLE_TESTS=OFF
    -DENABLE_TRACING=OFF
    -DENABLE_UNINSTALL=OFF)
set(mongoc-1.0_SHARED_LIBS OFF)
