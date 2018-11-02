#pragma once
#include "CMakeExampleLib_export.h"
#include <string>
#include <sstream>
#include <initializer_list>

namespace Example {

CMAKEEXAMPLE_LIB_EXPORT void printer(const std::string &str);

CMAKEEXAMPLE_LIB_EXPORT void printInfo();

template <typename... T>
void print(const T & ...v) {
    std::ostringstream ss;
    (void)std::initializer_list<int> {
        ((void) (ss << v), 0)...
    };
    printer(ss.str());
}

} // namespace Example
