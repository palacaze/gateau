set(Qwt_version "6.1.4")
set(Qwt_URL "https://sourceforge.net/projects/qwt/files/qwt/${Qwt_version}/qwt-${Qwt_version}.tar.bz2")
set(Qwt_MD5 "4fb1852f694420e3ab9c583526edecc5")

macro(Qwt_find name)
    include(FindPackageHandleStandardArgs)

    find_path(Qwt_INCLUDE_DIRS
        NAMES qwt_plot.h
        PATH_SUFFIXES qwt qwt6 qwt-qt5 qwt6-qt5
        HINTS ${Qt5_INCLUDE_DIRS}
    )

    find_library(Qwt_LIBRARIES
        NAMES qwt qwt6 qwt-qt5 qwt6-qt5
        HINTS ${Qt5_LIBRARY_DIRS}
    )

    find_package_handle_standard_args(
        Qwt DEFAULT_MSG Qwt_LIBRARIES Qwt_INCLUDE_DIRS)

    mark_as_advanced(Qwt_INCLUDE_DIRS Qwt_LIBRARIES)

    if(Qwt_FOUND AND NOT TARGET Qwt::Qwt)
        add_library(Qwt::Qwt UNKNOWN IMPORTED)
        set_target_properties(Qwt::Qwt PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
            INTERFACE_INCLUDE_DIRECTORIES "${Qwt_INCLUDE_DIRS}"
            IMPORTED_LOCATION "${Qwt_LIBRARIES}"
        )
    endif()
endmacro()

macro(Qwt_install name)
    if(WIN32)
        set(Qwt_MAKE_COMMAND mingw32-make)
    else()
        set(Qwt_MAKE_COMMAND make)
    endif()

    if (TARGET Qt5::qmake)
        get_target_property(Qwt_QMAKE_EXECUTABLE Qt5::qmake IMPORTED_LOCATION)
    else()
        message(FATAL_ERROR "QMake not found, can't install Qwt.")
    endif()

    socute_install_dependency(Qwt
        PATCH_COMMAND ${CMAKE_COMMAND} -DQWT_CONFIG_FILE=<SOURCE_DIR>/qwtconfig.pri -DQWT_INSTALL_DIR=<INSTALL_DIR> -P ${CMAKE_SOURCE_DIR}/cmake/qwt-patch.cmake
        CONFIGURE_COMMAND ${Qwt_QMAKE_EXECUTABLE} <SOURCE_DIR>/qwt.pro
        BUILD_COMMAND ${Qwt_MAKE_COMMAND} -j10
        INSTALL_COMMAND ${Qwt_MAKE_COMMAND} install
    )
endmacro()

