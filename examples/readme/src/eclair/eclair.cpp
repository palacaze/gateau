#include "eclair.hpp"

namespace eclair {

Eclair::Eclair(Flavour flavour, Size size)
    : m_flavour(flavour)
    , m_size(size)
{}

Flavour Eclair::flavour() const
{
    return m_flavour;
}

Size Eclair::size() const
{
    return m_size;
}

Eclair bake(Flavour flavour, Size sz)
{
    return Eclair(flavour, sz);
}

}  // namespace eclair

