# A function that appends text to a CACHE variable
function(socute_append_cached var str)
    list(APPEND ${var} ${str})
    if (${var})
        list(REMOVE_DUPLICATES ${var})
    endif()
    set(${var} ${${var}} CACHE STRINGS "" FORCE)
    mark_as_advanced(${var})
endfunction()

# build the snakecase name for a string
function(socute_to_snakecase var out)
    string(REPLACE " " "_" txt "${var}")
    string(REGEX REPLACE "([A-Z])" "_\\1" txt "${txt}")
    string(TOLOWER "${txt}" txt)
    if (${txt} MATCHES "^_")
        string(SUBSTRING "${txt}" 1 -1 txt)
    endif()
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# build a C identifier out of variable
function(socute_to_identifier var out)
    socute_to_snakecase(${var} txt)
    string(TOUPPER "${txt}" txt)
    set(${out} "${txt}" PARENT_SCOPE)
endfunction()

# build the short name from the module name
function(socute_target_short_name mod out)
    if (mod STREQUAL SOCUTE_PACKAGE)
        set(${out} ${SOCUTE_PACKAGE} PARENT_SCOPE)
    else()
        set(${out} ${SOCUTE_PACKAGE}${mod} PARENT_SCOPE)
    endif()
endfunction()

# build the fullname of a short module name
function(socute_target_full_name mod out)
    socute_target_short_name(${mod} short)
    set(${out} ${SOCUTE_ORGANIZATION}${short} PARENT_SCOPE)
endfunction()

# build the aliasname of a short module name
function(socute_target_alias_name mod out)
    socute_target_short_name(${mod} short)
    set(${out} ${SOCUTE_ORGANIZATION}::${short} PARENT_SCOPE)
endfunction()

# create the prefix string that will be used to namespace C macros in generated headers
function(socute_target_id_prefix mod out)
    # The first word of the string should contain the full organization name,
    # because it may be very ugly otherwise (wink at SoCute and its mid-word capital C).
    set(namespace ${SOCUTE_ORGANIZATION})
    string(TOLOWER "${namespace}" namespace)

    socute_target_short_name(${mod} short)
    set(id "${namespace}${short}")

    socute_to_identifier(${id} id)
    set(${out} ${id} PARENT_SCOPE)
endfunction()
