set(Libssh2_version 1.9.0)
set(Libssh2_URL "https://github.com/libssh2/libssh2/archive/libssh2-${Libssh2_version}.tar.gz")
set(Libssh2_MD5 "edbbea1b139cb22217813f860af803cb")
set(Libssh2_CMAKE_ARGS
    -DBUILD_EXAMPLES=OFF
    -DBUILD_TESTING=OFF
)

# macro(Libssh2_find name)
#     # Look for libssh2
#     include(FindPackageHandleStandardArgs)
#
# find_path(Libssh2_INCLUDE_DIRS NAMES libssh2.h)
# find_library(Libssh2_LIBRARIES NAMES ssh2)
#
# find_package_handle_standard_args(
#     Libssh2 DEFAULT_MSG Libssh2_LIBRARIES Libssh2_INCLUDE_DIRS)
#
# mark_as_advanced(Libssh2_LIBRARIES Libssh2_INCLUDE_DIRS)
#
#
# if(Libssh2_FOUND AND NOT TARGET Libssh2::libssh2)
#       add_library(Libssh2::libssh2 UNKNOWN IMPORTED)
#       set_target_properties(Libssh2::libssh2 PROPERTIES
#           IMPORTED_LINK_INTERFACE_LANGUAGES "C"
#           INTERFACE_INCLUDE_DIRECTORIES "${Libssh2_INCLUDE_DIRS}"
#           IMPORTED_LOCATION "${Libssh2_LIBRARIES}"
#       )
# endif()
