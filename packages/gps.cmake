# Look for system libgps from the gpsd package

macro(gps_find name)
    include(FindPkgConfig)
    pkg_check_modules(gps ${ARGN} libgps>3)

    if (gps_FOUND AND NOT TARGET gps::gps)
          add_library(gps::gps INTERFACE IMPORTED)
          set_target_properties(gps::gps PROPERTIES
              IMPORTED_LINK_INTERFACE_LANGUAGES "C"
              INTERFACE_INCLUDE_DIRECTORIES "${gps_INCLUDE_DIRS}"
              INTERFACE_LINK_LIBRARIES "${gps_LINK_LIBRARIES}"
              INTERFACE_LINK_OPTIONS "${gps_LDFLAGS_OTHER}"
              INTERFACE_COMPILE_OPTIONS "${gps_CFLAGS_OTHER}"
          )
    endif()
endmacro()


