# "live at head" they said
set(GTest_GIT "https://github.com/google/googletest.git")

macro(GTest_install name)
    gateau_install_dependency(GTest
        CMAKE_ARGS
            -DBUILD_GMOCK=OFF
            -DINSTALL_GTEST=ON
            -Dgtest_build_tests=OFF
    )

    gateau_install_dependency(GMock
        GIT "${GTest_GIT}"
        CMAKE_ARGS
            -DBUILD_GMOCK=ON
            -Dgmock_build_tests=OFF
    )
endmacro()
