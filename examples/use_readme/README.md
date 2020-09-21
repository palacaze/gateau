# Gourmand, a program using Eclair.

Assuming Eclair was previously built and installed to the `/tmp/local` prefix,
One can use eclair in other projects very easily.

To build, using the Ninja generator for instance, issue the following:

```
mkdir build && cd build
cmake -GNinja -DCMAKE_PREFIX_PATH=/tmp/local ..

# Build the binaries
cmake --build .

# profit
./gourmand
```

