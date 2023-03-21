if (asio_FOUND AND TARGET asio::asio)
    # Setup standalone and headers only asio 
    target_compile_definitions(asio::asio INTERFACE
        BOOST_ASIO_NO_DEPRECATED
        BOOST_ASIO_STANDALONE
        BOOST_ASIO_HEADER_ONLY
    )

    # asio needs some tweaks on Windows plateform
    if (WIN32)
        set_target_properties(asio::asio PROPERTIES
            INTERFACE_COMPILE_DEFINITIONS "_WIN32_WINNT=0x0601"
            INTERFACE_LINK_LIBRARIES "ws2_32;wsock32;mswsock"
        )
    endif()
endif()
