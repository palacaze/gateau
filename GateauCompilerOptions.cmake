#       Copyright Pierre-Antoine LACAZE 2018 - 2020.
# Distributed under the Boost Software License, Version 1.0.
#    (See accompanying file LICENSE_1_0.txt or copy at
#          https://www.boost.org/LICENSE_1_0.txt)

# We define in this module interface libraries whose role are to add compiler flags
# to a target. This is a convenient way of adding compiler options via the
# target_link_libraries() directive.
include_guard()

function(_gateau_setup_compiler_options)
    if (TARGET Gateau_CommonWarnings)
        return()
    endif()

    # Compilation generator expressions
    set(GATEAU_C_GCC "$<COMPILE_LANG_AND_ID:C,GNU>")
    set(GATEAU_CXX_GCC "$<COMPILE_LANG_AND_ID:CXX,GNU>")
    set(GATEAU_C_CXX_GCC "$<OR:${GATEAU_C_GCC},${GATEAU_CXX_GCC}>")

    set(GATEAU_C_CLANG "$<COMPILE_LANG_AND_ID:C,Clang,AppleClang>")
    set(GATEAU_CXX_CLANG "$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>")
    set(GATEAU_C_CXX_CLANG "$<OR:${GATEAU_C_CLANG},${GATEAU_CXX_CLANG}>")

    set(GATEAU_C_CLANG_GCC "$<COMPILE_LANG_AND_ID:C,Clang,AppleClang,GNU>")
    set(GATEAU_CXX_CLANG_GCC "$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang,GNU>")
    set(GATEAU_C_CXX_CLANG_GCC "$<OR:${GATEAU_C_CLANG_GCC},${GATEAU_CXX_CLANG_GCC}>")

    set(GATEAU_C_MSVC "$<COMPILE_LANG_AND_ID:C,MSVC>")
    set(GATEAU_CXX_MSVC "$<COMPILE_LANG_AND_ID:CXX,MSVC>")
    set(GATEAU_C_CXX_MSVC "$<OR:${GATEAU_C_MSVC},${GATEAU_CXX_MSVC}>")

    if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(_GATEAU_COMPILER_CLANG ON)
        set(GATEAU_COMPILER_CLANG ${_GATEAU_COMPILER_CLANG} PARENT_SCOPE)
    elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
        set(_GATEAU_COMPILER_GCC ON)
        set(GATEAU_COMPILER_GCC ${_GATEAU_COMPILER_GCC} PARENT_SCOPE)
    elseif (CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
        set(_GATEAU_COMPILER_MSVC ON)
        set(GATEAU_COMPILER_MSVC ${_GATEAU_COMPILER_MSVC} PARENT_SCOPE)
    endif()

    # Link generator expressions
    if (CMAKE_VERSION VERSION_LESS "3.18")
        set(GATEAU_LINK_C_CXX_GCC "$<BOOL:${_GATEAU_COMPILER_GCC}>")
        set(GATEAU_LINK_C_CXX_CLANG "$<BOOL:${_GATEAU_COMPILER_CLANG}>")
        set(GATEAU_LINK_C_CXX_CLANG_GCC "$<OR:${GATEAU_LINK_C_CXX_GCC},${GATEAU_LINK_C_CXX_CLANG}>")
        set(GATEAU_LINK_C_CXX_MSVC "$<BOOL:${_GATEAU_COMPILER_MSVC}>")
    else()
        set(GATEAU_LINK_C_GCC "$<LINK_LANG_AND_ID:C,GNU>")
        set(GATEAU_LINK_CXX_GCC "$<LINK_LANG_AND_ID:CXX,GNU>")
        set(GATEAU_LINK_C_CXX_GCC "$<OR:${GATEAU_LINK_C_GCC},${GATEAU_LINK_CXX_GCC}>")

        set(GATEAU_LINK_C_CLANG "$<LINK_LANG_AND_ID:C,Clang,AppleClang>")
        set(GATEAU_LINK_CXX_CLANG "$<LINK_LANG_AND_ID:CXX,Clang,AppleClang>")
        set(GATEAU_LINK_C_CXX_CLANG "$<OR:${GATEAU_LINK_C_CLANG},${GATEAU_LINK_CXX_CLANG}>")

        set(GATEAU_LINK_C_CLANG_GCC "$<LINK_LANG_AND_ID:C,Clang,AppleClang,GNU>")
        set(GATEAU_LINK_CXX_CLANG_GCC "$<LINK_LANG_AND_ID:CXX,Clang,AppleClang,GNU>")
        set(GATEAU_LINK_C_CXX_CLANG_GCC "$<OR:${GATEAU_LINK_C_CLANG_GCC},${GATEAU_LINK_CXX_CLANG_GCC}>")

        set(GATEAU_LINK_C_MSVC "$<LINK_LANG_AND_ID:C,MSVC>")
        set(GATEAU_LINK_CXX_MSVC "$<LINK_LANG_AND_ID:CXX,MSVC>")
        set(GATEAU_LINK_C_CXX_MSVC "$<OR:${GATEAU_LINK_C_MSVC},${GATEAU_LINK_CXX_MSVC}>")
    endif()

#    if (_GATEAU_COMPILER_GCC OR _GATEAU_COMPILER_CLANG)
#        set(CMAKE_C_FLAGS_DEBUG "-Og -g -gdwarf-3" CACHE STRING "" FORCE)
#        set(CMAKE_CXX_FLAGS_DEBUG "-Og -g -gdwarf-3" CACHE STRING "" FORCE)
#    endif()

    # Common warnings
    add_library(Gateau_CommonWarnings INTERFACE)
    target_compile_options(Gateau_CommonWarnings INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-Wall;-Wextra;-fdiagnostics-color=always;-pipe>
        $<${GATEAU_C_CXX_MSVC}:/W4>
        $<$<AND:${GATEAU_CXX_GCC},$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,7.0.0>>:-Wno-noexcept-type>
    )

    # Save temporaries
    add_library(Gateau_SaveTemps INTERFACE)
    target_compile_options(Gateau_SaveTemps INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-save-temps>
    )

    # Ultra verbose warnings
    add_library(Gateau_HighWarnings INTERFACE)
    target_compile_options(Gateau_HighWarnings INTERFACE
        $<${GATEAU_C_CXX_GCC}:
            -Wcast-qual;-Wconversion-null;-Wmissing-declarations;-Woverlength-strings;
            -Wpointer-arith;-Wunused-local-typedefs;-Wunused-result;-Wvarargs;-Wvla;
            -Wwrite-strings;-Wconversion;-Wsign-conversion;-Wodr;-Wpedantic;-pedantic;
            -Wcast-align;-Wctor-dtor-privacy;-Wdisabled-optimization;-Wformat=2;-Winit-self;
            -Wlogical-op;-Wmissing-include-dirs;-Wold-style-cast;-Woverloaded-virtual;
            -Wredundant-decls;-Wno-shadow;-Wsign-promo;-Wstrict-null-sentinel;-Wundef;
            -fdiagnostics-show-option;-Wno-array-bounds>
        $<${GATEAU_C_CXX_CLANG}:
            -Weverything; -Wno-unused-macros;
            -Wno-newline-eof;-Wno-exit-time-destructors;-Wno-global-constructors;
            -Wno-gnu-zero-variadic-macro-arguments;-Wno-documentation;-Wno-shadow-field-in-constructor;
            -Wno-missing-prototypes;-Wno-padded;-Wno-reserved-identifier;
            -Wno-documentation-unknown-command;-Wno-ctad-maybe-unsupported>
        $<$<AND:${GATEAU_C_CXX_CLANG},$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,16.0.0>>:
            -Wno-unsafe-buffer-usage;-Wno-date-time>
        $<${GATEAU_CXX_CLANG}:
            -Wno-c++98-compat;-Wno-c++98-compat-pedantic;-Wno-weak-vtables;-Wno-used-but-marked-unused>
        $<${GATEAU_C_CXX_MSVC}:/Wall>
    )

    # Turn some flags into errors
    add_library(Gateau_Werror INTERFACE)
    target_compile_options(Gateau_Werror INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -Werror=format-security;
            -Werror=return-type;
            -Werror=switch;
            -Werror=uninitialized>
        $<${GATEAU_CXX_CLANG_GCC}:-Werror=reorder>
        $<${GATEAU_C_CXX_MSVC}:/WX>
    )

# -ftime-trace compile options in Debug / RelWithDebInfo
    add_library(Gateau_TimeTrace INTERFACE)
    target_compile_options(Gateau_TimeTrace INTERFACE
        $<$<AND:$<CONFIG:Debug>,${GATEAU_C_CXX_CLANG_GCC}>:-ftime-trace>
        $<$<AND:$<CONFIG:RelWithDebInfo>,${GATEAU_C_CXX_CLANG_GCC}>:-ftime-trace>
    )

    # -march=native compile options in Release
    add_library(Gateau_MarchNative INTERFACE)
    target_compile_options(Gateau_MarchNative INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-march=native>
    )

    # Profiling
    add_library(Gateau_Profiling INTERFACE)
    target_compile_options(Gateau_Profiling INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-g;-fno-omit-frame-pointer>
    )

    # Debug Info
    add_library(Gateau_SplitDebugInfo INTERFACE)
    target_compile_options(Gateau_SplitDebugInfo INTERFACE
        $<$<AND:$<CONFIG:Debug>,${GATEAU_C_CXX_CLANG_GCC}>:-gsplit-dwarf>
        $<$<AND:$<CONFIG:RelWithDebInfo>,${GATEAU_C_CXX_CLANG_GCC}>:-gsplit-dwarf>
        $<$<AND:$<CONFIG:Debug>,${GATEAU_C_CXX_MSVC}>:/DEBUG:FASTLINK>
        $<$<AND:$<CONFIG:RelWithDebInfo>,${GATEAU_C_CXX_MSVC}>:/DEBUG:FASTLINK>
    )

    # sanitizers
    add_library(Gateau_AddressSanitizer INTERFACE)
    target_compile_options(Gateau_AddressSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=address;-fsanitize-address-use-after-scope>
    )
    target_link_libraries(Gateau_AddressSanitizer INTERFACE
        $<${GATEAU_LINK_C_CXX_CLANG_GCC}:-fsanitize=address>
    )

    add_library(Gateau_ThreadSanitizer INTERFACE)
    target_compile_options(Gateau_ThreadSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=thread>
    )
    target_link_libraries(Gateau_ThreadSanitizer INTERFACE
        $<${GATEAU_LINK_C_CXX_CLANG_GCC}:-fsanitize=thread>
    )

    add_library(Gateau_UndefinedSanitizer INTERFACE)
    target_compile_options(Gateau_UndefinedSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=undefined>
    )
    target_link_libraries(Gateau_UndefinedSanitizer INTERFACE
        $<${GATEAU_LINK_C_CXX_CLANG_GCC}:-fsanitize=undefined>
    )

    # Use the best linker available
    add_library(Gateau_Linker INTERFACE)
    foreach (_ld mold;lld;gold)
        execute_process(COMMAND "${CMAKE_CXX_COMPILER}" -fuse-ld=${_ld} -Wl,--version
            ERROR_QUIET OUTPUT_VARIABLE ld_version)
        if (ld_version)
            set(used_ld ${_ld})
            break()
        endif()
    endforeach()

    if (used_ld)
        target_link_libraries(Gateau_Linker INTERFACE
            -fuse-ld=${used_ld}
        )
    endif()

    # Use libcxx with clang
    add_library(Gateau_Libcxx INTERFACE)
    target_compile_options(Gateau_Libcxx INTERFACE
        $<${GATEAU_CXX_CLANG}:-stdlib=libc++>
    )
    target_link_libraries(Gateau_Libcxx INTERFACE
        $<${GATEAU_LINK_CXX_CLANG}:-stdlib=libc++;-rtlib=compiler-rt>
    )

endfunction()
