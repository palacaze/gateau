set(fmt_version "5.1.0")
set(fmt_url "https://github.com/fmtlib/fmt/archive/${fmt_version}.tar.gz")
set(fmt_md5 "89863cfec1448aec409a2eecf62600a2")

macro(pkg_find)
    find_package(fmt ${ARGN})
endmacro()

macro(pkg_install)
    include(SoCuteExternalPackage)

    socute_external_package(fmt
        CMAKE_ARGS
            "-DFMT_DOC=OFF"
            "-DFMT_TEST=OFF"
    )
endmacro()




