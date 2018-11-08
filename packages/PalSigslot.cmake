set(PalSigslot_version "1.0.1")
set(PalSigslot_url "https://github.com/palacaze/sigslot/archive/v${PalSigslot_version}.tar.gz")
set(PalSigslot_md5 "558788dcec230e5a956d7ace24be2603")

macro(pkg_find)
    find_package(PalSigslot ${PalSigslot_version} ${ARGN})
endmacro()

macro(pkg_install)
    include(SoCuteExternalPackage)

    socute_external_package(PalSigslot
        CMAKE_ARGS "-DCOMPILE_EXAMPLES=OFF"
                   "-DCOMPILE_TESTS=OFF"
    )
endmacro()
