set(date_GIT "https://github.com/HowardHinnant/date")
set(date_TAG "master")
set(date_CMAKE_ARGS
    -DUSE_SYSTEM_TZ_DB=ON
    -DBUILD_TZ_LIB=ON
)

macro(date_find name)
    find_package(date ${ARGN})

    # annoying compiler warning bug to disable
    if (date_FOUND AND TARGET date::date)
        target_compile_options(date::date INTERFACE $<$<CXX_COMPILER_ID:Clang,GNU>:-Wno-stringop-overflow>)
    endif()
endmacro()
