#include <eclair/eclair.hpp>

int main(int /*argc*/, char ** /*argv*/)
{
    for (auto f : {eclair::Flavour::Chocolate,
                   eclair::Flavour::Mint,
                   eclair::Flavour::Vanilla})
    {
        auto e = eclair::bake(f, eclair::Size::Big);
        fmt::print("Just ate an {}\n", e);
    }

    return 0;
}
