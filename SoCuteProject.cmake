# A wrapper over project() that declares the current project with the additional
# mandatory property ORGANIZATION, which populates the cache variable
# SOCUTE_ORGANIZATION. The name passed as first argument will be assigned to the
# SOCUTE_PACKAGE variable, and the full project name is the concatenation of
# the twe. This allows more finegrained target name handling.
# We also enforce filling every piece of information
macro(socute_project name)
    set(opts VERSION DESCRIPTION HOMEPAGE_URL ORGANIZATION)
    cmake_parse_arguments(SP "" "${opts}" "" ${ARGN})

    foreach(arg ${opts})
        if (NOT SP_${arg})
            message(FATAL_ERROR "The ${arg} argument of socute_project is missing")
        endif()
    endforeach()

    set(SOCUTE_ORGANIZATION "${SP_ORGANIZATION}" CACHE INTERNAL "")
    set(SOCUTE_PACKAGE "${name}" CACHE INTERNAL "")

    project(${SOCUTE_ORGANIZATION}${SOCUTE_PACKAGE}
            VERSION ${SP_VERSION}
            DESCRIPTION "${SP_DESCRIPTION}"
            HOMEPAGE_URL "${SP_HOMEPAGE_URL}"
            ${SP_UNPARSED_ARGUMENTS})
endmacro()
