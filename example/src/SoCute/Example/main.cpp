#include <QCoreApplication>
#include <QTimer>
#include "Foo.h"
#include "Printer.h"
#include "AppVersion.h"

int main(int argc, char **argv) {
    Example::printInfo();
    Example::print("App Name: ", SOCUTEEXAMPLE_APP_NAME);

    Example::Foo foo;
    const double a = 3, b = 4;

    Example::print("calc(", a, ", ", b, ") = ", foo.calc(a, b));

    QCoreApplication app(argc, argv);
    QTimer::singleShot(1000, [&]() { app.exit(); });
    return app.exec();
}
