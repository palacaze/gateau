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

# register a doctest test
function(_socute_register_doctest_test target wd)
    target_link_libraries(${target} PRIVATE doctest::doctest)

    cmake_parse_arguments(_O "" "" "PROPERTIES;ARGUMENTS" ${ARGN})
    if (_O_ARGUMENTS)
        set(args EXTRA_ARGS ${_O_ARGUMENTS})
    endif()
    if (_O_PROPERTIES)
        set(props PROPERTIES ${_O_PROPERTIES})
    endif()

    include(doctest)
    doctest_discover_tests(${target} WORKING_DIRECTORY "${wd}" ${args} ${props})
endfunction()

# register a catch test
function(_socute_register_catch_test target wd)
    target_link_libraries(${target} PRIVATE Catch2::Catch2)

    cmake_parse_arguments(_O "" "" "PROPERTIES;ARGUMENTS" ${ARGN})

    if (_O_ARGUMENTS)
        set(args EXTRA_ARGS ${_O_ARGUMENTS})
    endif()
    if (_O_PROPERTIES)
        set(props PROPERTIES ${_O_PROPERTIES})
    endif()

    include(Catch)
    catch_discover_tests(${target} WORKING_DIRECTORY "${wd}" ${args} ${props})
endfunction()

# Setup tests with optional test provider
macro(socute_setup_testing tests_target)
    set(bool_options CATCH DOCTEST)
    cmake_parse_arguments(_O "${bool_options}" "" "" ${ARGN})

    enable_testing()

    add_custom_target(${tests_target}
        COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure
        COMMENT "Build and run all the unit tests."
    )

    socute_set_project_var(TESTS_TARGET ${tests_target})

    # unit tests are provided by Catch2
    if (_O_CATCH)
        socute_find_package(Catch2 BUILD_DEP)
        socute_set_project_var(TEST_PROVIDER CATCH)
    elseif (_O_DOCTEST)
        socute_find_package(doctest BUILD_DEP)
        socute_set_project_var(TEST_PROVIDER DOCTEST)
    else()
        socute_set_project_var(TEST_PROVIDER UNKNOWN)
    endif()

    socute_cleanup_parsed(_O "${bool_options}" "" "")
    unset(bool_options)
endmacro()

# Add a test, this is the same as calling socute_add_executable,
# then performs auto-registration of the test
function(socute_add_test name)
    cmake_parse_arguments(_O "" "WORKING_DIRECTORY" "TEST_PROPERTIES;ARGUMENTS" ${ARGN})

    socute_add_executable(${name} ${_O_UNPARSED_ARGUMENTS} NO_INSTALL)

    socute_get_project_var(TESTS_TARGET tests_target)
    add_dependencies(${tests_target} ${name})

    if (NOT _O_WORKING_DIRECTORY)
        set(_O_WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
    if (_O_ARGUMENTS)
        set(args ARGUMENTS ${_O_ARGUMENTS})
    endif()
    if (_O_TEST_PROPERTIES)
        set(props PROPERTIES ${_O_TEST_PROPERTIES})
    endif()

    socute_get_project_var(TEST_PROVIDER provider)
    if (provider STREQUAL CATCH)
        _socute_register_catch_test(${name} "${_O_WORKING_DIRECTORY}" ${args} ${props})
    elseif(provider STREQUAL DOCTEST)
        _socute_register_doctest_test(${name} "${_O_WORKING_DIRECTORY}" ${args} ${props})
    else()
        _socute_register_test(${name} "${_O_WORKING_DIRECTORY}" ${args} ${props})
    endif()
endfunction()
