#       Copyright Pierre-Antoine LACAZE 2018 - 2020.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

# This module encapsulates add_test in order to ensure proper execution with
# Windows and linux-mingw plateforms
include_guard()
include(GateauHelpers)
include(GateauAddTarget)

# register a test
function(_gateau_register_test target wd)
    cmake_parse_arguments(_O "" "" "PROPERTIES;ARGUMENTS" ${ARGN})
    add_test(
        NAME test_${target}
        COMMAND ${target} ${_O_ARGUMENTS}
        WORKING_DIRECTORY "${wd}"
    )
    if (_O_PROPERTIES)
        set_tests_properties(test_${target} PROPERTIES ${_O_PROPERTIES})
    endif()
endfunction()

# register a google test
function(_gateau_register_gtest_test target wd)
    cmake_parse_arguments(_O "NO_MAIN" "" "PROPERTIES;ARGUMENTS" ${ARGN})
    if (_O_ARGUMENTS)
        set(args EXTRA_ARGS ${_O_ARGUMENTS})
    endif()
    if (_O_PROPERTIES)
        set(props PROPERTIES ${_O_PROPERTIES})
    endif()

    target_link_libraries(${target} PRIVATE GTest::gtest GTest::gmock)
    if (NOT _O_NO_MAIN)
        target_link_libraries(${target} PRIVATE GTest::gtest_main)
    endif()

    include(GoogleTest)
    gtest_discover_tests(${target} WORKING_DIRECTORY "${wd}" ${args} ${props})
endfunction()

# register a doctest test
function(_gateau_register_doctest_test target wd)
    cmake_parse_arguments(_O "NO_MAIN" "" "PROPERTIES;ARGUMENTS" ${ARGN})
    if (_O_ARGUMENTS)
        set(args EXTRA_ARGS ${_O_ARGUMENTS})
    endif()
    if (_O_PROPERTIES)
        set(props PROPERTIES ${_O_PROPERTIES})
    endif()

    target_link_libraries(${target} PRIVATE doctest::doctest)

    include(doctest)
    doctest_discover_tests(${target} WORKING_DIRECTORY "${wd}" ${args} ${props})
endfunction()

# register a catch test
function(_gateau_register_catch_test target wd)
    cmake_parse_arguments(_O "NO_MAIN" "" "PROPERTIES;ARGUMENTS" ${ARGN})

    if (_O_ARGUMENTS)
        set(args EXTRA_ARGS ${_O_ARGUMENTS})
    endif()
    if (_O_PROPERTIES)
        set(props PROPERTIES ${_O_PROPERTIES})
    endif()

    target_link_libraries(${target} PRIVATE Catch2::Catch2)

    include(Catch)
    catch_discover_tests(${target} WORKING_DIRECTORY "${wd}" ${args} ${props})
endfunction()

# register a QtTest test
function(_gateau_register_qttest_test target wd)
    target_link_libraries(${target} PRIVATE Qt5::Test)
    _gateau_register_test(${target} "${wd}" ${ARGN})
endfunction()

# Setup tests with optional test provider
macro(gateau_setup_testing tests_target)
    set(bool_options CATCH DOCTEST GTEST QTTEST)
    cmake_parse_arguments(_O "${bool_options}" "" "" ${ARGN})

    enable_testing()

    add_custom_target(${tests_target}
        COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure
        COMMENT "Build and run all the unit tests."
    )

    define_property(DIRECTORY PROPERTY gateau_tests_target INHERITED
        BRIEF_DOCS "tests target"
        FULL_DOCS "name of the main target to run all the tests"
    )
    define_property(DIRECTORY PROPERTY gateau_tests_provider INHERITED
        BRIEF_DOCS "tests provider"
        FULL_DOCS "name of the library used to write the tests"
    )

    set_directory_properties(PROPERTIES gateau_tests_target ${tests_target})

    # unit tests are provided by Catch2
    if (_O_CATCH)
        gateau_find_package(Catch2 BUILD_ONLY_DEP)
        set_directory_properties(PROPERTIES gateau_test_provider CATCH)
    elseif (_O_DOCTEST)
        gateau_find_package(doctest BUILD_ONLY_DEP)
        set_directory_properties(PROPERTIES gateau_test_provider DOCTEST)
    elseif (_O_GTEST)
        gateau_find_package(GTest BUILD_ONLY_DEP)
        set_directory_properties(PROPERTIES gateau_test_provider GTEST)
    elseif (_O_QTTEST)
        gateau_find_package(Qt5 COMPONENTS Test)
        set_directory_properties(PROPERTIES gateau_test_provider QTTEST)
    else()
        set_directory_properties(PROPERTIES gateau_test_provider UNKNOWN)
    endif()

    gateau_cleanup_parsed(_O "${bool_options}" "" "")
    unset(bool_options)
endmacro()

# Add a test, this is the same as calling gateau_add_executable,
# then performs auto-registration of the test
function(gateau_add_test name)
    cmake_parse_arguments(_O "NO_MAIN" "WORKING_DIRECTORY" "TEST_PROPERTIES;ARGUMENTS" ${ARGN})

    gateau_add_executable(${name} ${_O_UNPARSED_ARGUMENTS} NO_INSTALL)

    get_directory_property(tests_target gateau_tests_target)
    add_dependencies(${tests_target} ${name})

    if (NOT _O_WORKING_DIRECTORY)
        set(_O_WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
    set(args)
    if (_O_NO_MAIN)
        list(APPEND args NO_MAIN)
    endif()
    if (_O_ARGUMENTS)
        list(APPEND args ARGUMENTS ${_O_ARGUMENTS})
    endif()
    if (_O_TEST_PROPERTIES)
        list(APPEND args PROPERTIES ${_O_TEST_PROPERTIES})
    endif()

    get_directory_property(provider gateau_test_provider)
    if (provider STREQUAL CATCH)
        _gateau_register_catch_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    elseif(provider STREQUAL DOCTEST)
        _gateau_register_doctest_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    elseif(provider STREQUAL GTEST)
        _gateau_register_gtest_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    elseif(provider STREQUAL QTTEST)
        _gateau_register_qttest_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    else()
        _gateau_register_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    endif()
endfunction()
