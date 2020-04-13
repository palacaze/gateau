# We define in this module interface libraries whose role are to add compiler flags
# to a target. This is a convenient way of adding compiler options via the
# target_link_libraries() directive.
include_guard()

function(_gateau_setup_compiler_options)
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
            -Wwrite-strings;-Wconversion;-Wsign-conversion;-Wodr;-Wpedantic>
        $<${GATEAU_C_CXX_CLANG}:
            -Weverything; -Wno-unused-macros;
            -Wno-newline-eof;-Wno-exit-time-destructors;-Wno-global-constructors;
            -Wno-gnu-zero-variadic-macro-arguments;-Wno-documentation;-Wno-shadow;
            -Wno-missing-prototypes;-Wno-padded>
        $<${GATEAU_CXX_CLANG}:
            -Wno-c++98-compat;-Wno-c++98-compat-pedantic;-Wno-weak-vtables>
        $<${GATEAU_C_CXX_MSVC}:/Wall>
    )

    # Turn some flags into errors
    add_library(Gateau_Werror INTERFACE)
    target_compile_options(Gateau_Werror INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -Werror=format-security;
            -Werror=reorder;
            -Werror=return-type;
            -Werror=switch;
            -Werror=uninitialized>
        $<${GATEAU_C_CXX_MSVC}:/WX>
    )

    # Profiling
    add_library(Gateau_Profiling INTERFACE)
    target_compile_options(Gateau_Profiling INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-g;-fno-omit-frame-pointer>
    )

    # sanitizers
    add_library(Gateau_AddressSanitizer INTERFACE)
    target_compile_options(Gateau_AddressSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=address;-fsanitize-address-use-after-scope>
    )
    target_link_libraries(Gateau_AddressSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-fsanitize=address>
    )

    add_library(Gateau_ThreadSanitizer INTERFACE)
    target_compile_options(Gateau_ThreadSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=thread>
    )
    target_link_libraries(Gateau_ThreadSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-fsanitize=thread>
    )

    add_library(Gateau_UndefinedSanitizer INTERFACE)
    target_compile_options(Gateau_UndefinedSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=undefined>
    )
    target_link_libraries(Gateau_UndefinedSanitizer INTERFACE
        $<${GATEAU_C_CXX_CLANG_GCC}:-fsanitize=undefined>
    )

    # Use the best linker available on linux/unix
    add_library(Gateau_Linker INTERFACE)
    if (UNIX AND NOT APPLE AND NOT CYGWIN)
        foreach (_ld lld;gold)
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
    endif()

    # Use libcxx with clang
    add_library(Gateau_Libcxx INTERFACE)
    target_compile_options(Gateau_Libcxx INTERFACE
        $<${GATEAU_CXX_CLANG}:-stdlib=libc++>
    )
    target_link_libraries(Gateau_Libcxx INTERFACE
        $<${GATEAU_CXX_CLANG}:-stdlib=libc++;-rtlib=compiler-rt>
    )
endfunction()