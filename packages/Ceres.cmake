# Ceres Solver
set(Ceres_version "2.0.0")
set(Ceres_URL "https://github.com/ceres-solver/ceres-solver/archive/${Ceres_version}.tar.gz")
set(Ceres_MD5 "94246057ac520313e3b582c45a30db6e")
set(Ceres_CMAKE_ARGS
    -DDEFAULT_CXX_STANDARD=17
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
    -DBUILD_DOCUMENTATION=OFF
    -DBUILD_BENCHMARKS=OFF
    -DEIGENSPARSE=ON
    -DMINIGLOG=OFF
    -DGFLAGS=OFF
    -DLAPACK=ON
    -DCXSPARSE=OFF
    -DSUITESPARSE=OFF
)
set(Ceres_SHARED_LIBS ON)
