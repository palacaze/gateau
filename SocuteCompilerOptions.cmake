# We define in this module interface libraries whose role are to add compiler flags
# to a target. This is a convenient way of adding compiler options via the
# target_link_libraries() directive.

function(_socute_setup_compiler_options)
    set(SOCUTE_C_GCC "$<COMPILE_LANG_AND_ID:C,GNU>")
    set(SOCUTE_CXX_GCC "$<COMPILE_LANG_AND_ID:CXX,GNU>")
    set(SOCUTE_C_CXX_GCC "$<OR:${SOCUTE_C_GCC},${SOCUTE_CXX_GCC}>")

    set(SOCUTE_C_CLANG "$<COMPILE_LANG_AND_ID:C,Clang,AppleClang>")
    set(SOCUTE_CXX_CLANG "$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang>")
    set(SOCUTE_C_CXX_CLANG "$<OR:${SOCUTE_C_CLANG},${SOCUTE_CXX_CLANG}>")

    set(SOCUTE_C_CLANG_GCC "$<COMPILE_LANG_AND_ID:C,Clang,AppleClang,GNU>")
    set(SOCUTE_CXX_CLANG_GCC "$<COMPILE_LANG_AND_ID:CXX,Clang,AppleClang,GNU>")
    set(SOCUTE_C_CXX_CLANG_GCC "$<OR:${SOCUTE_C_CLANG_GCC},${SOCUTE_CXX_CLANG_GCC}>")

    set(SOCUTE_C_MSVC "$<COMPILE_LANG_AND_ID:C,MSVC>")
    set(SOCUTE_CXX_MSVC "$<COMPILE_LANG_AND_ID:CXX,MSVC>")
    set(SOCUTE_C_CXX_MSVC "$<OR:${SOCUTE_C_MSVC},${SOCUTE_CXX_MSVC}>")

    # Common warnings
    add_library(Socute_CommonWarnings INTERFACE)
    target_compile_options(Socute_CommonWarnings INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:-Wall;-Wextra;-fdiagnostics-color=always;-pipe>
        $<${SOCUTE_C_CXX_MSVC}:/W4>
        $<$<AND:${SOCUTE_CXX_GCC},$<VERSION_GREATER_EQUAL:$<CXX_COMPILER_VERSION>,7.0.0>>:-Wno-noexcept-type>
    )

    # Save temporaries
    add_library(Socute_SaveTemps INTERFACE)
    target_compile_options(Socute_SaveTemps INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:-save-temps>
    )

    # Ultra verbose warnings
    add_library(Socute_HighWarnings INTERFACE)
    target_compile_options(Socute_HighWarnings INTERFACE
        $<${SOCUTE_C_CXX_GCC}:
            -Wcast-qual;-Wconversion-null;-Wmissing-declarations;-Woverlength-strings;
            -Wpointer-arith;-Wunused-local-typedefs;-Wunused-result;-Wvarargs;-Wvla;
            -Wwrite-strings;-Wconversion;-Wsign-conversion;-Wodr;-Wpedantic>
        $<${SOCUTE_C_CXX_CLANG}:
            -Weverything; -Wno-unused-macros;
            -Wno-newline-eof;-Wno-exit-time-destructors;-Wno-global-constructors;
            -Wno-gnu-zero-variadic-macro-arguments;-Wno-documentation;-Wno-shadow;
            -Wno-missing-prototypes;-Wno-padded>
        $<${SOCUTE_CXX_CLANG}:
            -Wno-c++98-compat;-Wno-c++98-compat-pedantic;-Wno-weak-vtables>
        $<${SOCUTE_C_CXX_MSVC}:/Wall>
    )

    # Profiling
    add_library(Socute_Profiling INTERFACE)
    target_compile_options(Socute_Profiling INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:-g;-fno-omit-frame-pointer>
    )

    # sanitizers
    add_library(Socute_AddressSanitizer INTERFACE)
    target_compile_options(Socute_AddressSanitizer INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=address;-fsanitize-address-use-after-scope>
    )
    target_link_libraries(Socute_AddressSanitizer INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:-fsanitize=address>
    )

    add_library(Socute_ThreadSanitizer INTERFACE)
    target_compile_options(Socute_ThreadSanitizer INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=thread>
    )
    target_link_libraries(Socute_ThreadSanitizer INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:-fsanitize=thread>
    )

    add_library(Socute_UndefinedSanitizer INTERFACE)
    target_compile_options(Socute_UndefinedSanitizer INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:
            -g;-fno-omit-frame-pointer;-fsanitize=undefined>
    )
    target_link_libraries(Socute_UndefinedSanitizer INTERFACE
        $<${SOCUTE_C_CXX_CLANG_GCC}:-fsanitize=undefined>
    )

    # Use the best linker available on linux/unix
    add_library(Socute_Linker INTERFACE)
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
            target_link_libraries(Socute_Linker INTERFACE
                -fuse-ld=${used_ld}
            )
        endif()
    endif()

    # Use libcxx with clang
    add_library(Socute_Libcxx INTERFACE)
    target_compile_options(Socute_Libcxx INTERFACE
        $<${SOCUTE_CXX_CLANG}:-stdlib=libc++>
    )
    target_link_libraries(Socute_Libcxx INTERFACE
        $<${SOCUTE_CXX_CLANG}:-stdlib=libc++;-rtlib=compiler-rt>
    )
endfunction()
