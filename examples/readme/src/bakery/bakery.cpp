#include <cstdlib>
#include <string_view>
#include <eclair/eclair.hpp>

int main(int argc, char **argv) {
    if (argc != 3) {
        return 1;
    }

    eclair::Flavour flavour = eclair::Flavour::Mint;

    std::string_view flav_str = argv[1];
    std::string_view size_str = argv[2];

    if (flav_str == "mint") {
        flavour = eclair::Flavour::Mint;
    } else if (flav_str == "chocolate") {
        flavour = eclair::Flavour::Chocolate;
    }

    auto sz = size_str == "big" ? eclair::Size::Big : eclair::Size::Medium;

    auto e = eclair::bake(flavour, sz);
    fmt::print("{}\n", e);
    return 0;
}

