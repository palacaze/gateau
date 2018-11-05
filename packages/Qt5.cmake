set(Qt5_version 5.10.0)

macro(pkg_find)
    find_package(Qt5 ${Qt5_version} ${ARGN} REQUIRED)

    # We add some definitions that make Qt stricter
    if (TARGET Qt5::Core)
        set_property(TARGET Qt5::Core PROPERTY
            INTERFACE_COMPILE_DEFINITIONS
                QT_NO_CAST_FROM_BYTEARRAY
                QT_NO_CAST_FROM_ASCII
                QT_NO_CAST_TO_ASCII
                QT_NO_URL_CAST_FROM_STRING
                QT_STRICT_ITERATORS
                QBAL=QByteArrayLiteral
                QSL=QStringLiteral
                QL1S=QLatin1String
                QL1C=QLatin1Char
                QT_FORCE_ASSERTS
            APPEND
        )
    endif()
endmacro()

macro(pkg_install)
    message(FATAL_ERROR "Eh. I don't know how to build Qt.")
endmacro()
