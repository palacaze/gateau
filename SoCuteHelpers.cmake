# A function that appends text to a CACHE variable
function(socute_append_cached var str)
    list(APPEND ${var} ${str})
    if (${var})
        list(REMOVE_DUPLICATES ${var})
    endif()
    set(${var} ${${var}} CACHE STRING "" FORCE)
    mark_as_advanced(${var})
endfunction()

# Build the snakecase name for a string
function(socute_to_snakecase var out)
    string(REPLACE " " "_" txt "${var}")
    string(REGEX REPLACE "([A-Z])" "_\\1" txt "${txt}")
    string(TOLOWER "${txt}" txt)
    if (${txt} MATCHES "^_")
        string(SUBSTRING "${txt}" 1 -1 txt)
    endif()
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build a C identifier out of variable
function(socute_to_identifier var out)
    socute_to_snakecase(${var} txt)
    string(TOUPPER "${txt}" txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build a cmake target out of variable
function(socute_to_target var out)
    string(REPLACE "::" "" txt "${var}")
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build a sub folder out of variable
function(socute_to_subfolder var out)
    string(REPLACE "::" "/" txt "${var}")
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build a sub filename out of variable
function(socute_to_filename var out)
    string(REPLACE "::" "_" txt "${var}")
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build a domain name out of variable
function(socute_to_domain var out)
    string(REPLACE "::" "." txt "${var}")
    string(TOLOWER "${txt}" txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build the export name of a module name
function(socute_target_export_name name out)
    # It is not possible to give per target namespace when generating
    # the XXXTargets.cmake file, let abuse the export name for that purpose then.
    if ("${name}" STREQUAL "${SOCUTE_PACKAGE_EXPORT_NAME}")
        set(${out} "${name}" PARENT_SCOPE)
    else()
        set(${out} "${SOCUTE_PACKAGE_EXPORT_NAME}::${name}" PARENT_SCOPE)
    endif()
endfunction()

# Build the fullname of a short module name
function(socute_target_full_name name out)
    if ("${name}" STREQUAL "${SOCUTE_PACKAGE_EXPORT_NAME}")
        set(txt "${SOCUTE_PACKAGE}")
    else()
        string(JOIN "::" txt "${SOCUTE_PACKAGE}" "${name}")
    endif()

    socute_to_target(${txt} txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build the alias name of a short module name
function(socute_target_alias_name name out)
    if ("${name}" STREQUAL "${SOCUTE_PACKAGE_EXPORT_NAME}")
        set(txt "${SOCUTE_PACKAGE}")
    else()
        string(JOIN "::" txt "${SOCUTE_PACKAGE}" "${name}")
    endif()

    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build the filename of a short module name
function(socute_target_file_name name out)
    if ("${name}" STREQUAL "${SOCUTE_PACKAGE_EXPORT_NAME}")
        set(txt "${SOCUTE_PACKAGE}")
    else()
        string(JOIN "::" txt "${SOCUTE_PACKAGE}" "${name}")
    endif()

    socute_to_filename(${txt} txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# Build the prefix name that will be used to namespace C macros in generated headers
function(socute_target_identifier_name name out)
    # The first word of the string should contain the full organization name,
    # because it may be very ugly otherwise (wink at SoCute and its mid-word capital C).
    string(TOLOWER "${SOCUTE_ORGANIZATION}" lower_organization)
    string(LENGTH "${lower_organization}" lower_organization_length)
    socute_target_full_name("${name}" tfn)
    string(SUBSTRING "${tfn}" ${lower_organization_length} -1 tfn)
    string(JOIN "" txt "${lower_organization}" "${tfn}")
    socute_to_identifier(${txt} txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()
