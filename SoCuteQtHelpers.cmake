# This module contains helpers that simplify working with Qt

# Function that queries all qmake properties and exposes them in the parent scope.
function(socute_read_qt_properties)
    # qmake executable is needed to query properties
    if (TARGET Qt5::qmake)
        get_target_property(QMAKE_LOCATION Qt5::qmake IMPORTED_LOCATION)
    else()
        message(WARNING "qmake not found, Qmake properties undefined.")
    endif()

    execute_process(
        COMMAND "${QMAKE_LOCATION}" -query
        OUTPUT_VARIABLE QMAKE_PROPERTIES
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REPLACE "\n" ";" QMAKE_PROPERTIES ${QMAKE_PROPERTIES})

    foreach(property ${QMAKE_PROPERTIES})
        string(REPLACE ":" ";" property ${property})
        list(GET property 0 PROPERTY_NAME)
        list(GET property 1 PROPERTY_VALUE)
        set(${PROPERTY_NAME} "${PROPERTY_VALUE}" PARENT_SCOPE)
    endforeach()
endfunction()

# Function that creates translations files and automatically updates them and
# generates their binary representation.
function(socute_add_qt_translations target)
    set(opts_single TS_DIR QM_DIR)
    set(opts_multi LOCALES TS_OPTIONS)
    cmake_parse_arguments(SAQT "" "${opts_single}" "${opts_multi}" ${ARGN})

    foreach(arg ${opts_single} ${opts_multi})
        if (NOT SAQT_${arg} AND NOT "${arg}" STREQUAL "TS_OPTIONS")
            message(FATAL_ERROR "The ${arg} argument of socute_add_translations is missing")
        endif()
    endforeach()

    socute_target_full_name(${target} target_name)

    foreach(locale ${SAQT_LOCALES})
        set(basename "${PROJECT_NAME}_${target}")
        string(TOLOWER "${basename}" basename)
        list(APPEND ts_files "${SAQT_TS_DIR}/${basename}_${locale}.ts")
    endforeach()

    get_target_property(sources ${target_name} SOURCES)

    qt5_create_translation(qm_files ${sources} ${ts_files} OPTIONS ${SAQT_TS_OPTIONS})

    target_sources(${target_name}
        PRIVATE
            ${qm_files}
    )

    add_custom_command(
        TARGET ${target_name}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory ${SAQT_QM_DIR}
        COMMAND ${CMAKE_COMMAND} -E copy ${qm_files} ${SAQT_QM_DIR}
    )
endfunction()

# Function that installs translations files for target
function(socute_install_qt_translations target install_trdir)
    socute_target_full_name(${target} target_name)

    get_target_property(sources ${target_name} SOURCES)

    foreach(source ${sources})
        if (${source} MATCHES ".+\\.qm$")
            list(APPEND qm_files "${source}")
        endif()
    endforeach()

    install(FILES ${qm_files} DESTINATION ${install_trdir})
endfunction()
