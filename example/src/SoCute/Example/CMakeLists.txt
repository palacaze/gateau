# find our dependencies
socute_find_package(Qt5 COMPONENTS Core)
socute_find_package(RapidJSON)

# declare a library, only path the short Name
socute_add_library(Lib
    Foo.h
    Foo.cpp
    Printer.h
    Printer.cpp
)

# here we need the fully qualified name of the lib
target_link_libraries(SoCuteExampleLib
    PRIVATE
        RapidJSON::RapidJSON
)

socute_install_target(Lib)


# declare an executable
socute_add_executable(App
    main.cpp
)

target_link_libraries(SoCuteExampleApp
    PRIVATE
        SoCuteExample::Lib
        Qt5::Core
)

socute_install_target(App)
