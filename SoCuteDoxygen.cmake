# This module can be used to generate documentation for a SoCute project.
# It generates an appropriate Doxygen project file from a generic template and
# adds a "docs" target to the project that will build the documentation on demand.

# config option for documentation installation
set(SOCUTE_DOCUMENTATION_ROOT "" CACHE PATH "Documentation installation root directory.")

# Get the directory where all the documentation will be installed.
# SOCUTE_DOCUMENATION_ROOT may be supplied to cmake at configure time, otherwise the
# environment variable of the same name will be picked. At last the fallback will
# be ${SOCUTE_BINARY_DIR}/doc.
function(socute_get_documentation_dir dir)
    if (NOT SOCUTE_DOCUMENTATION_ROOT)
        set(SOCUTE_DOCUMENTATION_ROOT "$ENV{SOCUTE_DOCUMENTATION_ROOT}")
        if (NOT SOCUTE_DOCUMENTATION_ROOT)
            set(SOCUTE_DOCUMENTATION_ROOT "${CMAKE_BINARY_DIR}/doc")
        endif()
    endif()

    socute_to_target("${SOCUTE_PACKAGE}" package_target)
    string(APPEND SOCUTE_DOCUMENTATION_ROOT "/${package_target}")
    set(${dir} "${SOCUTE_DOCUMENTATION_ROOT}" PARENT_SCOPE)
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
    list(APPEND GD_INPUT_PATHS src README.md)
    list(APPEND GD_EXCLUDED_PATHS src/3rdparty)

    # we automatically add EXPORT macros generated for every library
    get_property(targets GLOBAL PROPERTY SOCUTE_LIBRARY_LIST)
    foreach(lib ${targets})
        socute_target_identifier_name(${lib} target_identifier)
        list(APPEND GD_PREDEFINED_MACROS ${target_identifier}_EXPORT)
    endforeach()

    # Build Doxygen compatible value list
    function(create_doxygen_list list_in string_out)
        list(JOIN list_in "\" \"" out)
        set(${string_out} "\"${out}\"" PARENT_SCOPE)
    endfunction()

    set(PACKAGE_NAME ${SOCUTE_PACKAGE})
    set(PACKAGE_DESCRIPTION ${PROJECT_DESCRIPTION})
    set(PACKAGE_VERSION ${PROJECT_VERSION})
    socute_to_domain(${SOCUTE_PACKAGE} PACKAGE_DOMAIN)
    set(PACKAGE_DOMAIN "com.${PACKAGE_DOMAIN}")

    socute_get_documentation_dir(DOXYGEN_OUTPUT)
    file(MAKE_DIRECTORY ${DOXYGEN_OUTPUT})
    if (NOT IS_DIRECTORY ${DOXYGEN_OUTPUT})
        message(ERROR "Could not create directory ${DOXYGEN_OUTPUT} for documentation installation.\n"
            "Please modify SOCUTE_DOCUMENTATION_ROOT option or env var to a valid path.")
        return()
    endif()

    set(DOXYGEN_IN ${SOCUTE_CMAKE_MODULES_DIR}/templates/Doxyfile.in)
    set(DOXYGEN_OUT ${CMAKE_BINARY_DIR}/doc/Doxyfile)

    # qhelpgenerator executable is needed to generate a qch file
    find_package(Qt5 COMPONENTS Help)
    if (TARGET Qt5::qhelpgenerator)
        get_target_property(DOXYGEN_QHG_LOCATION Qt5::qhelpgenerator IMPORTED_LOCATION)
    else()
        message(WARNING "qhelpgenerator not found, Qt compatible documentation won't be built")
    endif()

    create_doxygen_list("${GD_INPUT_PATHS}" DOXYGEN_INPUT)
    create_doxygen_list("${GD_EXCLUDED_PATHS}" DOXYGEN_EXCLUDE)
    create_doxygen_list("${GD_EXCLUDED_SYMBOLS}" DOXYGEN_EXCLUDE_SYMBOLS)
    create_doxygen_list("${GD_PREDEFINED_MACROS}" DOXYGEN_PREDEFINED)

    configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT})
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
        COMMAND Doxygen::doxygen ${CMAKE_BINARY_DIR}/doc/Doxyfile
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Generating API documentation with Doxygen"
        VERBATIM
    )
endfunction()
