socute_find_package(Qt5 COMPONENTS Core)
socute_find_package(RapidJSON)

socute_add_library(CMakeExample::Lib
    Foo.h
    Foo.cpp
    Printer.h
    Printer.cpp
)

target_link_libraries(CMakeExampleLib
    PRIVATE
        RapidJSON::RapidJSON
)

socute_add_executable(CMakeExampleApp
    main.cpp
)

target_link_libraries(CMakeExampleApp
    PRIVATE
        CMakeExample::Lib
        Qt5::Core
)
