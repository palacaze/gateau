# We define in this module interface libraries whose role is to add compiler flags
# to a target. This is a convenient way of adding compiler options via the
# target_compile_options() directive.

# Common warnings
add_library(Socute_CommonWarnings INTERFACE)
add_library(Socute::CommonWarnings ALIAS Socute_CommonWarnings)
target_compile_options(Socute_CommonWarnings INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:-Wall;-Wextra;-fdiagnostics-color=always;-pipe>
    $<$<AND:$<BOOL:${SOCUTE_COMPILER_GCC}>,$<VERSION_GREATER_EQUAL:${CMAKE_CXX_COMPILER_VERSION},7.0.0>>:-Wno-noexcept-type>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>
)

add_library(Socute_SaveTemps INTERFACE)
add_library(Socute::SaveTemps ALIAS Socute_SaveTemps)
target_compile_options(Socute_SaveTemps INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:-save-temps>
)

# Ultra verbose warnings
add_library(Socute_HighWarnings INTERFACE)
add_library(Socute::HighWarnings ALIAS Socute_HighWarnings)
target_link_libraries(Socute_HighWarnings INTERFACE Socute_HighWarnings)
target_compile_options(Socute_HighWarnings INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_GCC}>:
        -Wcast-qual;-Wconversion-null;-Wmissing-declarations;-Woverlength-strings;
        -Wpointer-arith;-Wunused-local-typedefs;-Wunused-result;-Wvarargs;-Wvla;
        -Wwrite-strings;-Wconversion;-Wsign-conversion -Wodr>
    $<$<BOOL:${SOCUTE_COMPILER_CLANG}>:
        -Weverything;-Wno-c++98-compat;-Wno-c++98-compat-pedantic; -Wno-unused-macros;
        -Wno-newline-eof;-Wno-exit-time-destructors;-Wno-global-constructors;
        -Wno-gnu-zero-variadic-macro-arguments;-Wno-documentation;-Wno-shadow;
        -Wno-missing-prototypes;-Wno-padded;-Wno-weak-vtables>
    $<$<CXX_COMPILER_ID:MSVC>:/Wall>
)

# Profiling
add_library(Socute_Profiling INTERFACE)
add_library(Socute::Profiling ALIAS Socute_Profiling)
target_compile_options(Socute_Profiling INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:-g;-fno-omit-frame-pointer>
)

# sanitizers
add_library(Socute_AddressSanitizer INTERFACE)
add_library(Socute::AddressSanitizer ALIAS Socute_AddressSanitizer)
target_compile_options(Socute_AddressSanitizer INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:
        -g;-fno-omit-frame-pointer;-fsanitize=address;-fsanitize-address-use-after-scope>
)
target_link_libraries(Socute_AddressSanitizer INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:-fsanitize=address>
)

add_library(Socute_ThreadSanitizer INTERFACE)
add_library(Socute::ThreadSanitizer ALIAS Socute_ThreadSanitizer)
target_compile_options(Socute_ThreadSanitizer INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:
        -g;-fno-omit-frame-pointer;-fsanitize=thread>
)
target_link_libraries(Socute_ThreadSanitizer INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:-fsanitize=thread>
)

add_library(Socute_UndefinedSanitizer INTERFACE)
add_library(Socute::UndefinedSanitizer ALIAS Socute_UndefinedSanitizer)
target_compile_options(Socute_UndefinedSanitizer INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:
        -g;-fno-omit-frame-pointer;-fsanitize=undefined>
)
target_link_libraries(Socute_UndefinedSanitizer INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG_OR_GCC}>:-fsanitize=undefined>
)

# Use the best linker available
if (UNIX AND SOCUTE_COMPILER_CLANG_OR_GCC)
    foreach (_ld lld;gold)
        execute_process(COMMAND ${CMAKE_CXX_COMPILER} -fuse-ld=${_ld} -Wl,--version
            ERROR_QUIET OUTPUT_VARIABLE ld_version)
        if (ld_version)
            set(used_ld ${_ld})
            break()
        endif()
    endforeach()

    add_library(Socute_Linker INTERFACE)
    add_library(Socute::Linker ALIAS Socute_Linker)

    if (used_ld)
        set_target_properties(Socute_Linker PROPERTIES
            INTERFACE_LINK_LIBRARIES "-fuse-ld=${used_ld}"
        )
    endif()
endif()

# Use libcxx with clang
add_library(Socute_Libcxx INTERFACE)
add_library(Socute::Libcxx ALIAS Socute_Libcxx)
target_compile_options(Socute_Libcxx INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG}>:-stdlib=libc++>
)
target_link_libraries(Socute_Libcxx INTERFACE
    $<$<BOOL:${SOCUTE_COMPILER_CLANG}>:-stdlib=libc++;-rtlib=compiler-rt>
)

# Use CCACHE
option(SOCUTE_USE_CCACHE "Use Ccache to speed-up compilation" OFF)
if (SOCUTE_USE_CCACHE)
    find_program(CCACHE_PROGRAM ccache)
    if (CCACHE_PROGRAM)
        set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
        set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}")
    endif()
endif()

