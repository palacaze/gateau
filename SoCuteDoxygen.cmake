# This module can be used to generate documentation for a SoCute project.
# It generates an appropriate Doxygen project file from a generic template and
# adds a "docs" target to the project that will build the documentation on demand.

# Generate a Doxygen file for this package from a template and a few variables
function(socute_generate_doxygen_file excluded_symbols predefined_macros input_paths excluded_paths)
    # Build Doxygen compatible value list
    function(create_doxygen_list list_in string_out)
        list(JOIN list_in " " out)
        set(${string_out} "${out}" PARENT_SCOPE)
    endfunction()

    set(PACKAGE_ORGANIZATION ${SOCUTE_ORGANIZATION})
    string(TOLOWER ${PACKAGE_ORGANIZATION} PACKAGE_ORGANIZATION_LOWER)
    set(PACKAGE_NAME ${SOCUTE_PACKAGE})
    string(TOLOWER ${PACKAGE_NAME} PACKAGE_NAME_LOWER)
    socute_target_alias_name(${SOCUTE_PACKAGE} PACKAGE_FULL_NAME)
    set(PACKAGE_DESCRIPTION ${PROJECT_DESCRIPTION})
    set(PACKAGE_VERSION ${PROJECT_VERSION})

    set(DOXYGEN_OUTPUT ${CMAKE_BINARY_DIR}/doc)
    set(DOXYGEN_IN ${SOCUTE_CMAKE_MODULES_DIR}/templates/Doxyfile.in)
    set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/doc/Doxyfile)

    # qhelpgenerator executable is needed to generate a qch file
    find_package(Qt5 COMPONENTS Help)
    if (TARGET Qt5::qhelpgenerator)
        get_target_property(DOXYGEN_QHG_LOCATION Qt5::qhelpgenerator IMPORTED_LOCATION)
    else()
        message(WARNING "qhelpgenerator not found, Qt compatible documentation won't be built")
    endif()

    create_doxygen_list("${input_paths}" DOXYGEN_INPUT)
    create_doxygen_list("${excluded_paths}" DOXYGEN_EXCLUDE)
    create_doxygen_list("${excluded_symbols}" DOXYGEN_EXCLUDE_SYMBOLS)
    create_doxygen_list("${predefined_macros}" DOXYGEN_PREDEFINED)

    configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT})
endfunction()

# Generate documentation for this socute package
# The following options are supported. each of them accepts a list
# - EXCLUDED_SYMBOLS: list of symbols to exclude from the documentation, defaults to "Detail"
# - PREDEFINED_MACROS: C macros to define, with an optional value, when parsing files
# - INPUT_PATHS: input paths whose files should be parsed in addition to "src and README.md"
# - EXCLUDED_PATHS: pathes that should be excluded from the parsing, defaults to src/3rdparty
function(socute_build_documentation)
    set(opts EXCLUDED_SYMBOLS PREDEFINED_MACROS INPUT_PATHS EXCLUDED_PATHS)
    cmake_parse_arguments(GD "" "" "${opts}" ${ARGN})

    list(APPEND GD_EXCLUDED_SYMBOLS Detail)
    list(APPEND GD_PREDEFINED_MACROS DOXYGEN_IGNORE)
    list(APPEND GD_INPUT_PATHS src README.md)
    list(APPEND GD_EXCLUDED_PATHS src/3rdparty)

    find_package(Doxygen)
    if (NOT DOXYGEN_FOUND)
        message(WARNING "Doxygen not found, documentation won't be built")
        return()
    endif()

    socute_generate_doxygen_file(
        "${GD_EXCLUDED_SYMBOLS}" "${GD_PREDEFINED_MACROS}"
        "${GD_INPUT_PATHS}" "${GD_EXCLUDED_PATHS}")

    add_custom_target(docs
        COMMAND Doxygen::doxygen ${CMAKE_BINARY_DIR}/doc/Doxyfile
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Generating API documentation with Doxygen"
        VERBATIM
    )
endfunction()
