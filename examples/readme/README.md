# Eclair, a mock project relying on Gateau as its build system

It consists in a library, `eclair` and an application `bakery`.
The project uses a couple a external dependencies, tests, Doxygen documentation
and can be installed.

To build, using the Ninja generator for instance, issue the following:

```
mkdir build && cd build
cmake -GNinja -DCMAKE_INSTALL_PREFIX=/tmp/local ..

# Build the binaries
cmake --build .

# Also compile the tests
cmake --build . --target tests

# And build the doc
cmake --build . --target docs

# Install the project
cmake --build . --target install
```

