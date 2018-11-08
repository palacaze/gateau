set(Catch2_version "master")
set(Catch2_git "https://github.com/catchorg/Catch2.git")

macro(pkg_find)
    find_package(Catch2 ${ARGN})
endmacro()

macro(pkg_install)
    include(SoCuteExternalPackage)

    socute_external_package(Catch2
        CMAKE_ARGS "-DBUILD_TESTING=OFF"
    )
endmacro()
