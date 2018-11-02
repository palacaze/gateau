socute_add_library(CMakeExample::Lib
    Foo.h
    Foo.cpp
    Printer.h
    Printer.cpp)

socute_add_executable(CMakeExampleApp
    main.cpp)

target_link_libraries(CMakeExampleApp
    PRIVATE
        CMakeExample::Lib)
