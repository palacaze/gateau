#pragma once

#include "CMakeExampleLib_export.h"
#include <string>
#include <sstream>
#include <initializer_list>

namespace Example {

void CMAKEEXAMPLE_LIB_EXPORT printer(const std::string &str);

void CMAKEEXAMPLE_LIB_EXPORT printInfo();

template <typename... T>
void print(const T & ...v) {
    std::ostringstream ss;
    (void)std::initializer_list<int> {
        ((void) (ss << v), 0)...
    };
    printer(ss.str());
}

} // namespace Example
