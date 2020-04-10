# This module encapsulates add_test in order to ensure proper execution with
# Windows and linux-mingw plateforms
include_guard()
include(SocuteHelpers)
include(SocuteAddTarget)

# register a test
function(_socute_register_test target wd)
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
function(_socute_register_gtest_test target wd)
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
function(_socute_register_doctest_test target wd)
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
function(_socute_register_catch_test target wd)
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

# Setup tests with optional test provider
macro(socute_setup_testing tests_target)
    set(bool_options CATCH DOCTEST GTEST)
    cmake_parse_arguments(_O "${bool_options}" "" "" ${ARGN})

    enable_testing()

    add_custom_target(${tests_target}
        COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure
        COMMENT "Build and run all the unit tests."
    )

    set_directory_properties(PROPERTIES socute_tests_target ${tests_target})

    # unit tests are provided by Catch2
    if (_O_CATCH)
        socute_find_package(Catch2 BUILD_ONLY_DEP)
        set_directory_properties(PROPERTIES socute_test_provider CATCH)
    elseif (_O_DOCTEST)
        socute_find_package(doctest BUILD_ONLY_DEP)
        set_directory_properties(PROPERTIES socute_test_provider DOCTEST)
    elseif (_O_GTEST)
        socute_find_package(GTest BUILD_ONLY_DEP)
        set_directory_properties(PROPERTIES socute_test_provider GTEST)
    else()
        set_directory_properties(PROPERTIES socute_test_provider UNKNOWN)
    endif()

    socute_cleanup_parsed(_O "${bool_options}" "" "")
    unset(bool_options)
endmacro()

# Add a test, this is the same as calling socute_add_executable,
# then performs auto-registration of the test
function(socute_add_test name)
    cmake_parse_arguments(_O "NO_MAIN" "WORKING_DIRECTORY" "TEST_PROPERTIES;ARGUMENTS" ${ARGN})

    socute_add_executable(${name} ${_O_UNPARSED_ARGUMENTS} NO_INSTALL)

    get_directory_property(tests_target socute_tests_target)
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

    get_directory_property(provider socute_test_provider)
    if (provider STREQUAL CATCH)
        _socute_register_catch_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    elseif(provider STREQUAL DOCTEST)
        _socute_register_doctest_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    elseif(provider STREQUAL GTEST)
        _socute_register_gtest_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    else()
        _socute_register_test(${name} "${_O_WORKING_DIRECTORY}" ${args})
    endif()
endfunction()
