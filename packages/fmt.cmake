set(fmt_VERSION "9.0.0")
set(fmt_URL "https://github.com/fmtlib/fmt/archive/${fmt_VERSION}.tar.gz")
set(fmt_MD5 "d56c8b0612b049bb1854f07c8b133f3c")
set(fmt_CMAKE_ARGS
    -DFMT_DOC=OFF
    -DFMT_TEST=OFF
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    -DFMT_ARM_ABI_COMPATIBILITY=ON
)
