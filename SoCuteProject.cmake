# A wrapper over project() that declares the current project with two additional
# mandatory properties ORGANIZATION and PACKAGE, which populate the two cache
# variables SOCUTE_ORGANIZATION and SOCUTE_PACKAGE which allow more finegrained
# target name handling.
# We also enforce filling every piece of information
macro(socute_project name)
    set(opts VERSION DESCRIPTION HOMEPAGE_URL ORGANIZATION PACKAGE)
    cmake_parse_arguments(SP "" "${opts}" "" ${ARGN})

    foreach(arg ${opts})
        if (NOT SP_${arg})
            message(FATAL_ERROR "The ${arg} argument of socute_project is missing")
        endif()
    endforeach()

    set(SOCUTE_ORGANIZATION "${SP_ORGANIZATION}" CACHE INTERNAL "")
    set(SOCUTE_PACKAGE "${SP_PACKAGE}" CACHE INTERNAL "")

    project(${name}
            VERSION ${SP_VERSION}
            DESCRIPTION "${SP_DESCRIPTION}"
            HOMEPAGE_URL "${SP_HOMEPAGE_URL}"
            ${SP_UNPARSED_ARGUMENTS})
endmacro()
