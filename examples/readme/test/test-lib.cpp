#include <doctest/doctest.h>
#include <eclair/eclair.hpp>

using namespace eclair;

TEST_CASE("eclair bake default size")
{
    auto e = bake(Flavour::Mint);
    REQUIRE(e.flavour() == Flavour::Mint);
    REQUIRE(e.size() == Size::Medium);
}

TEST_CASE("eclair bake big size")
{
    auto e = bake(Flavour::Chocolate, Size::Big);
    REQUIRE(e.flavour() == Flavour::Chocolate);
    REQUIRE(e.size() == Size::Big);
}

