set(asio_GIT "https://github.com/chriskohlhoff/asio.git")
set(asio_TAG "asio-1-18-1")

macro(asio_find name)
    include(FindPackageHandleStandardArgs)

    find_path(asio_INCLUDE_DIR
        NAMES io_service.hpp
        PATH_SUFFIXES asio
    )

    find_package_handle_standard_args(
        asio DEFAULT_MSG asio_INCLUDE_DIR)

    mark_as_advanced(asio_INCLUDE_DIR)

    if(asio_FOUND AND NOT TARGET asio::asio)
        add_library(asio::asio INTERFACE IMPORTED)
        set_target_properties(asio::asio PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${asio_INCLUDE_DIR}"
        )
        target_compile_definitions(asio::asio INTERFACE
            BOOST_ASIO_NO_DEPRECATED
            BOOST_ASIO_STANDALONE
            BOOST_ASIO_HEADER_ONLY
        )

        if (WIN32)
            set_target_properties(asio::asio PROPERTIES
                INTERFACE_COMPILE_DEFINITIONS "_WIN32_WINNT=0x0601"
                INTERFACE_LINK_LIBRARIES "ws2_32;wsock32;mswsock"
            )
        endif()
    endif()
endmacro()

macro(asio_install name)
    # call to external project, which installs the dep
    gateau_install_dependency(${name}
        NO_PATCH
        NO_CONFIGURE
        NO_BUILD
        INSTALL_COMMAND ${CMAKE_COMMAND} -E make_directory "<INSTALL_DIR>/include/asio"
                COMMAND ${CMAKE_COMMAND} -E copy_directory "<SOURCE_DIR>/asio/include/asio" "<INSTALL_DIR>/include/asio"
                COMMAND ${CMAKE_COMMAND} -E copy "<SOURCE_DIR>/asio/include/asio.hpp" "<INSTALL_DIR>/include"
    )
endmacro()

