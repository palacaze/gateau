set(PalSigslot_version "master")
set(PalSigslot_git "https://github.com/palacaze/sigslot.git")

macro(pkg_find)
    find_package(PalSigslot ${ARGN})
endmacro()

macro(pkg_install)
    include(SoCuteExternalPackage)

    socute_external_package(PalSigslot
        CMAKE_ARGS "-DCOMPILE_EXAMPLES=OFF"
                   "-DCOMPILE_TESTS=OFF"
    )
endmacro()
