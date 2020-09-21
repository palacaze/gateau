#pragma once
#include <eclair/lib-export.hpp>
#include <string_view>
#include <fmt/format.h>

/**
 * @file eclair.hpp
 */

/**
 * The eclair namespace
 */
namespace eclair {

/**
 * Available flavours
 */
enum class Flavour {
    Chocolate,  ///< Chocolate flavour
    Vanilla,    ///< Vanilla flavour
    Mint        ///< Mint flavour
};

/**
 * Possible Eclair sizes
 */
enum class Size {
    Medium,  ///< Medium size
    Big      ///< Big size
};

/**
 * The object of our obsession
 */
struct ECLAIR_LIB_EXPORT Eclair {
public:
    explicit Eclair(Flavour flavour, Size size);

    /// The flavour of the Eclair
    Flavour flavour() const;

    /// The Size of the Eclair
    Size size() const;

private:
    Flavour m_flavour;
    Size m_size;
};

/**
 * Bake an Eclair with the given specs.
 * @param flavour The requested Flavour
 * @param size The requested Size
 * @return An Eclair meeting the specs in argument
 */
ECLAIR_LIB_EXPORT Eclair bake(Flavour flavour, Size sz = Size::Medium);

}  // namespace eclair


// make Eclair::Flavour printable
template <>
struct fmt::formatter<eclair::Flavour> : fmt::formatter<std::string> {
    template <typename FormatContext>
    auto format(const eclair::Flavour &s, FormatContext &ctx)
    {
        static constexpr std::array<std::string_view, 3> labels = {
            "Chocolate", "Vanilla", "Mint" };
        return format_to(ctx.out(), "{}", labels[static_cast<size_t>(s)]);
    }
};

// make eclair::Size printable
template <>
struct fmt::formatter<eclair::Size> : fmt::formatter<std::string> {
    template <typename FormatContext>
    auto format(const eclair::Size &s, FormatContext &ctx)
    {
        static constexpr std::array<std::string_view, 2> labels = {
            "Medium", "Big" };
        return format_to(ctx.out(), "{}", labels[static_cast<size_t>(s)]);
    }
};

// make eclair printable
template <>
struct fmt::formatter<eclair::Eclair> : fmt::formatter<std::string> {
    template <typename FormatContext>
    auto format(const eclair::Eclair &s, FormatContext &ctx)
    {
        return format_to(ctx.out(), "Eclair favour {}, size {}", s.flavour(), s.size());
    }
};

