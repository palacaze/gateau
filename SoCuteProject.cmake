# A wrapper over project() that declares the current project with the additional
# mandatory property ORGANIZATION, which populates the cache variable
# SOCUTE_ORGANIZATION. The name (possibly namespaced) passed as first argument will
# be concataned with the ORGANIZATION to form a full namespaced SOCUTE_PACKAGE name
# used for the final project name (ie Organization::OptonalNamespace::Name).
# This allows more finegrained target name handling.
# We also enforce filling every piece of information.
macro(socute_project name)
    set(opts VERSION DESCRIPTION HOMEPAGE_URL ORGANIZATION)
    cmake_parse_arguments(SP "" "${opts}" "" ${ARGN})

    foreach(arg ${opts})
        if (NOT SP_${arg} AND NOT "${arg}" STREQUAL "ORGANIZATION")
            message(FATAL_ERROR "The ${arg} argument of socute_project is missing")
        endif()
    endforeach()

    if (SP_ORGANIZATION)
        string(JOIN "::" SOCUTE_PACKAGE "${SP_ORGANIZATION}" "${name}")
    else()
        set(SOCUTE_PACKAGE "${name}")
    endif()

    string(REPLACE "::" ";" package_list ${SOCUTE_PACKAGE})
    list(GET package_list -1 SOCUTE_PACKAGE_EXPORT_NAME)
    list(REMOVE_AT package_list -1)
    list(JOIN package_list "::" SOCUTE_PACKAGE_EXPORT_NAMESPACE)

    if (SP_ORGANIZATION)
        set(SOCUTE_ORGANIZATION "${SP_ORGANIZATION}" CACHE INTERNAL "")
    endif()
    set(SOCUTE_PACKAGE_EXPORT_NAMESPACE "${SOCUTE_PACKAGE_EXPORT_NAMESPACE}" CACHE INTERNAL "")
    set(SOCUTE_PACKAGE_EXPORT_NAME "${SOCUTE_PACKAGE_EXPORT_NAME}" CACHE INTERNAL "")
    set(SOCUTE_PACKAGE "${SOCUTE_PACKAGE}" CACHE INTERNAL "")

    project(${SOCUTE_PACKAGE}
            VERSION ${SP_VERSION}
            DESCRIPTION "${SP_DESCRIPTION}"
            HOMEPAGE_URL "${SP_HOMEPAGE_URL}"
            ${SP_UNPARSED_ARGUMENTS}
    )
endmacro()
