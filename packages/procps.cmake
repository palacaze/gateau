# find module for https://gitlab.com/procps-ng/procps
macro(procps_find name)
    include(FindPackageHandleStandardArgs)

    if (DEFINED ${name}_INCLUDE_DIR AND NOT EXISTS "${${name}_INCLUDE_DIR}/proc/readproc.h")
        unset(${name}_INCLUDE_DIR CACHE)
    endif()
    if (DEFINED ${name}_LIBRARY AND NOT EXISTS "${${name}_LIBRARY}")
        unset(${name}_LIBRARY CACHE)
    endif()

    find_path(${name}_INCLUDE_DIR
        NAMES readproc.h
        PATH_SUFFIXES proc
    )

    find_library(${name}_LIBRARY NAMES procps)

    find_package_handle_standard_args(
        ${name} DEFAULT_MSG ${name}_LIBRARY ${name}_INCLUDE_DIR)

    mark_as_advanced(${name}_LIBRARY ${name}_INCLUDE_DIR)

    if(${name}_FOUND AND NOT TARGET ${name}::${name})
        add_library(${name}::${name} UNKNOWN IMPORTED)
        set_target_properties(${name}::${name} PROPERTIES
            IMPORTED_LINK_INTERFACE_LANGUAGES C
            INTERFACE_INCLUDE_DIRECTORIES "${${name}_INCLUDE_DIR}"
            IMPORTED_LOCATION "${${name}_LIBRARY}"
        )
    endif()
endmacro()

macro(procps_install name)
    message(SEND_ERROR
        "I do not now how to install ${name}.
        Install it from your Linux distribution with `apt install libprocps-dev`,
        or manually from https://gitlab.com/procps-ng/procps."
    )
endmacro()

