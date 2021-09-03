#set(Eigen3_VERSION "3.3.7")
#set(Eigen3_MD5 "05b1f7511c93980c385ebe11bd3c93fa")
#set(Eigen3_URL "http://bitbucket.org/eigen/eigen/get/${Eigen3_VERSION}.tar.bz2")
set(Eigen3_GIT "https://gitlab.com/libeigen/eigen")
set(Eigen3_TAG "master")
set(Eigen3_CMAKE_ARGS
    -DBUILD_TESTING=OFF
    -DEIGEN_BUILD_DOC=OFF
)

