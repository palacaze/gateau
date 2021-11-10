set(Qwt_ver "6.2.0")
set(Qwt_URL "https://downloads.sourceforge.net/qwt/qwt-${Qwt_ver}.tar.bz2")
set(Qwt_MD5 "00c94f0af8b29d4785cec47351127c00")

macro(Qwt_install name)
    gateau_install_dependency(Qwt
        PATCH_COMMAND "${CMAKE_COMMAND}" -E copy "${Qwt_PATCH_DIR}/CMakeLists.txt" "${Qwt_PATCH_DIR}/QwtConfig.cmake.in" <SOURCE_DIR>
    )
endmacro()

