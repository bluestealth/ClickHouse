#pragma once

#include <algorithm>

template<std::size_t len, class... Types>
struct AlignedUnion
{
    static constexpr std::size_t alignment_value = std::max({alignof(Types)...});
    struct Type
    {
        alignas(alignment_value) char s[std::max({len, sizeof(Types)...})];
    };
};

template<std::size_t len, class... Types>
using AlignedUnionT = typename AlignedUnion<len, Types...>::Type;
