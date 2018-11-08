#pragma once
#include "LibExport.h"
#include <string>
#include <sstream>
#include <initializer_list>

namespace Example {

SOCUTEEXAMPLE_LIB_EXPORT void printer(const std::string &str);

SOCUTEEXAMPLE_LIB_EXPORT void printInfo();

template <typename... T>
void print(const T & ...v) {
    std::ostringstream ss;
    (void)std::initializer_list<int> {
        ((void) (ss << v), 0)...
    };
    printer(ss.str());
}

} // namespace Example
