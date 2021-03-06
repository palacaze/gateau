#set(Eigen3_VERSION "3.3.7")
#set(Eigen3_MD5 "05b1f7511c93980c385ebe11bd3c93fa")
#set(Eigen3_URL "http://bitbucket.org/eigen/eigen/get/${Eigen3_VERSION}.tar.bz2")
set(Eigen3_GIT "https://gitlab.com/libeigen/eigen")

macro(Eigen3_find name)
    find_package(${name} CONFIG ${ARGN})
endmacro()
