# the name of the target operating system
set(CMAKE_SYSTEM_NAME Windows)

set(SOCUTE_COMPILER_PREFIX x86_64-w64-mingw32)
set(SOCUTE_COMPILER_THREAD_IMPL posix)

# which compilers to use for C and C++
find_program(CMAKE_RC_COMPILER NAMES ${SOCUTE_COMPILER_PREFIX}-windres)
find_program(CMAKE_C_COMPILER NAMES ${SOCUTE_COMPILER_PREFIX}-gcc-${SOCUTE COMPILER_THREAD_IMPL})
find_program(CMAKE_CXX_COMPILER NAMES ${SOCUTE_COMPILER_PREFIX}-g++-${SOCUTE_COMPILER_THREAD_IMPL})

# here is the target environment located
set(CMAKE_FIND_ROOT_PATH /usr/${SOCUTE_COMPILER_PREFIX})

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search 
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# find wine
find_program(WINE NAMES wine)
set(CROSSCOMPILING_EMULATOR "${WINE}")

# determine library path for later execution of executables with wine
execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} -print-search-dirs
    OUTPUT_VARIABLE COMPILER_LIBRARIES
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
    
string(FIND "${COMPILER_LIBRARIES}" "libraries: =" POS)
string(SUBSTRING "${COMPILER_LIBRARIES}" ${POS} -1 COMPILER_LIBRARIES)
string(REGEX REPLACE "libraries: =([^ ]*)" "\\1" COMPILER_LIBRARIES "${COMPILER_LIBRARIES}")
string(REPLACE ":" "\;" CROSS_COMPILER_LIBRARIES "${COMPILER_LIBRARIES}")
