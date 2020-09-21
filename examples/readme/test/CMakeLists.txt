gateau_setup_testing(tests DOCTEST)

gateau_add_test(test-lib
    SOURCES
        test-lib.cpp
        test-main.cpp
    LINK_LIBRARIES
        eclair::lib
)

