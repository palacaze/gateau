# This module can be used to generate documentation for a Socute project.
# It generates an appropriate Doxygen project file from a generic template and
# adds a "docs" target to the project that will build the documentation on demand.

include(SocuteHelpers)

# Get the directory where all the documentation will be installed.
# The DOCUMENATION_ROOT option may be supplied in various ways (see _socute_get_optional_var).
# The fallback is ${PROJECT_BINARY_DIR}/doc.
function(socute_get_documentation_dir dir)
    socute_get_optional_var(DOCUMENTATION_ROOT "${PROJECT_BINARY_DIR}/doc" doc_root)
    set(${dir} "${doc_root}/${PROJECT_NAME}" PARENT_SCOPE)
endfunction()

# Generate a Doxygen file for this package from a template and a few variables
function(socute_generate_doxygen_file)
    set(opts EXCLUDED_SYMBOLS PREDEFINED_MACROS INPUT_PATHS EXCLUDED_PATHS)
    cmake_parse_arguments(GD "" "" "${opts}" ${ARGN})

    # build lists of custom configuration entries
    list(APPEND GD_EXCLUDED_SYMBOLS Detail)
    list(APPEND GD_PREDEFINED_MACROS
        DOXYGEN_IGNORE=1
        Q_NAMESPACE Q_DECLARE_LOGGING_CATEGORY Q_OBJECT Q_GADGET Q_BEGIN_NAMESPACE Q_END_NAMESPACE
    )

    # append source dirs to the input paths to scan
    socute_get_project_var(RELATIVE_HEADERS_DIRS relative_dirs)
    foreach(rel_dir ${relative_dirs})
        set(_sdir "${PROJECT_SOURCE_DIR}/${rel_dir}")
        if (IS_DIRECTORY "${_sdir}")
            list(APPEND GD_INPUT_PATHS "${_sdir}")
        endif()
    endforeach()
    if (EXISTS README.md)
        list(APPEND GD_INPUT_PATHS README.md)
    endif()

    # we automatically add EXPORT macros generated for every non interface library
    socute_get_project_var(KNOWN_TARGETS targets)
    foreach(tgt ${targets})
        get_target_property(_type ${tgt} TYPE)
        if ((NOT _type STREQUAL "INTERFACE_LIBRARY") AND (NOT _type STREQUAL "EXECUTABLE"))
            socute_target_identifier_name(${tgt} ident)
            list(APPEND GD_PREDEFINED_MACROS ${ident}_EXPORT)
        endif()
    endforeach()

    # Build Doxygen compatible value list
    function(create_doxygen_list list_in string_out)
        list(JOIN list_in "\" \"" out)
        set(${string_out} "\"${out}\"" PARENT_SCOPE)
    endfunction()

    set(PACKAGE_NAME ${PROJECT_NAME})
    set(PACKAGE_DESCRIPTION ${PROJECT_DESCRIPTION})
    set(PACKAGE_VERSION ${PROJECT_VERSION})
    string(TOLOWER "com.${PROJECT_NAME}" PACKAGE_DOMAIN)

    socute_get_documentation_dir(DOXYGEN_OUTPUT)
    file(MAKE_DIRECTORY "${DOXYGEN_OUTPUT}")
    if (NOT IS_DIRECTORY "${DOXYGEN_OUTPUT}")
        message(ERROR "Could not create directory ${DOXYGEN_OUTPUT} for documentation installation.\n"
            "Please modify the SOCUTE_DOCUMENTATION_ROOT option or env var to a valid path.")
        return()
    endif()

    # qhelpgenerator executable is needed to generate a qch file
    find_package(Qt5 COMPONENTS Help QUIET)
    if (TARGET Qt5::qhelpgenerator)
        get_target_property(DOXYGEN_QHG_LOCATION Qt5::qhelpgenerator IMPORTED_LOCATION)
    else()
        message(WARNING "qhelpgenerator not found, Qt compatible documentation won't be built")
    endif()

    create_doxygen_list("${GD_INPUT_PATHS}" DOXYGEN_INPUT)
    create_doxygen_list("${GD_EXCLUDED_PATHS}" DOXYGEN_EXCLUDE)
    create_doxygen_list("${GD_EXCLUDED_SYMBOLS}" DOXYGEN_EXCLUDE_SYMBOLS)
    create_doxygen_list("${GD_PREDEFINED_MACROS}" DOXYGEN_PREDEFINED)
    socute_get_project_var(TEMPLATES_DIR templates)
    set(DOXYGEN_IN "${templates}/Doxyfile.in")
    set(DOXYGEN_OUT "${PROJECT_BINARY_DIR}/doc/Doxyfile")
    configure_file("${DOXYGEN_IN}" "${DOXYGEN_OUT}")
endfunction()

# Generate documentation for this socute package
# The following options are supported. each of them accepts a list
# - EXCLUDED_SYMBOLS: list of symbols to exclude from the documentation, defaults to "Detail"
# - PREDEFINED_MACROS: C macros to define, with an optional value, when parsing files
# - INPUT_PATHS: input paths whose files should be parsed in addition to "src and README.md"
# - EXCLUDED_PATHS: paths that should be excluded from the parsing, defaults to src/3rdparty
function(socute_build_documentation)
    find_package(Doxygen)
    if (NOT DOXYGEN_FOUND)
        message(WARNING "Doxygen not found, documentation won't be built")
        return()
    endif()

    socute_generate_doxygen_file("${ARGN}")

    add_custom_target(docs
        COMMAND Doxygen::doxygen "${PROJECT_BINARY_DIR}/doc/Doxyfile"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
        COMMENT "Generating API documentation with Doxygen"
        VERBATIM
    )
endfunction()
