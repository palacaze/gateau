#include "Foo.h"
#include "Printer.h"
#include "CMakeExampleApp_version.h"

int main(int /*argc*/, char ** /*argv*/) {
    Example::printInfo();

    Example::print("App Name: ", CMAKEEXAMPLEAPP_NAME);

    Example::Foo foo;
    const double a = 3, b = 4;

    Example::print("calc(", a, ", ", b, ") = ", foo.calc(a, b));

    return 0;
}
