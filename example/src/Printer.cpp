#include <iostream>
#include <rapidjson/rapidjson.h>
#include "Printer.h"
#include "CMakeExampleLib_version.h"

namespace Example {

void printInfo() {
    print(
        "CMakeExampleLib Info:\n",
        "\tName: ", CMAKEEXAMPLE_LIB_NAME, "\n",
        "\tVersion: ", CMAKEEXAMPLE_LIB_VERSION, "\n",
        "\tRevision: ", CMAKEEXAMPLE_LIB_REVISION, "\n",
        "\tRapidJson: ", RAPIDJSON_VERSION_STRING
    );

    // volontary leak
    new char[10];
}

void printer(const std::string &str) {
    std::cout << str << std::endl;
}

} // namespace Example
