set(glog_VERSION 0.6.0)
set(glog_URL "https://github.com/google/glog/archive/refs/tags/v${glog_VERSION}.tar.gz")
set(glog_MD5 "c98a6068bc9b8ad9cebaca625ca73aa2")
# set(glog_GIT "https://github.com/google/glog.git")
set(glog_CMAKE_ARGS
    -DWITH_GFLAGS=OFF
    -DWITH_UNWIND=OFF
    -DWITH_SYMBOLIZE=OFF
)
set(glog_SHARED_LIBS ON)
