set(Catch2_GIT "https://github.com/catchorg/Catch2.git")
set(Catch2_TAG "devel")
set(Catch2_CMAKE_ARGS
    -DCMAKE_CXX_STANDARD=17
    -DCATCH_DEVELOPMENT_BUILD=OFF
    -DCATCH_INSTALL_DOCS=OFF
    -DCATCH_INSTALL_EXTRAS=ON
)
