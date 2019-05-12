set(benchmark_version "master")
set(benchmark_git "https://github.com/google/benchmark.git")

macro(pkg_find)
    find_package(benchmark)
endmacro()

macro(pkg_install)
    include(SoCuteExternalPackage)
    socute_external_package(benchmark
        CMAKE_ARGS
            "-DBENCHMARK_ENABLE_TESTING=OFF"
            "-DBENCHMARK_ENABLE_EXCEPTIONS=OFF"
    )
endmacro()
