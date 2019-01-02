set(celero_version "master")
set(celero_git "https://github.com/DigitalInBlue/Celero.git")

macro(pkg_find)
    include(FindPackageHandleStandardArgs)

    find_path(celero_INCLUDE_DIRS
        NAMES Celero.h
        PATH_SUFFIXES celero
    )

    find_library(celero_LIBRARIES NAMES celero)

    find_package_handle_standard_args(
        celero DEFAULT_MSG celero_LIBRARIES celero_INCLUDE_DIRS)

    if(celero_FOUND)
        get_filename_component(celero_INCLUDE_DIRS
            "${celero_INCLUDE_DIRS}/.." ABSOLUTE)
    endif()

    mark_as_advanced(celero_LIBRARIES celero_INCLUDE_DIRS)

    if(celero_FOUND AND NOT TARGET celero)
          add_library(celero UNKNOWN IMPORTED)
          set_target_properties(celero PROPERTIES
              INTERFACE_INCLUDE_DIRECTORIES "${celero_INCLUDE_DIRS}"
              IMPORTED_LOCATION "${celero_LIBRARIES}"
          )
    endif()
endmacro()

macro(pkg_install)
    include(SoCuteExternalPackage)
    socute_external_package(celero
        CMAKE_ARGS
            "-DCMAKE_DEBUG_POSTFIX="
            "-"
    )
endmacro()
