# An example of creating a simple injector with package:inject.
#
# This project is analyzed by tests within the main package.

load(
    "//dart:build_defs.bzl",
    "dart_library",
    "dart_vm_binary",
    "dart_vm_test",
)

package(
    default_testonly = 1,
    default_visibility = ["//third_party/dart/inject:internal"],
)

licenses(["notice"])  # New BSD

exports_files(["LICENSE"])

dart_vm_binary(
    name = "brew",
    script_file = "bin/brew.dart",
    deps = [
        ":coffee",
    ],
)

dart_library(
    name = "coffee",
    srcs = glob(["lib/**/*.dart"]),
    generate_for = [
        "lib/coffee_app.dart",
        "lib/src/coffee_maker.dart",
        "lib/src/drip_coffee_module.dart",
        "lib/src/thermosiphon.dart",
    ],
    license_files = ["LICENSE"],
    deps = [
        "//third_party/dart/inject",
    ],
)

dart_vm_test(
    name = "coffee_app_test",
    srcs = [],
    # If this test generates a dart_library, then both this target and :test
    # will attempt to generate "test/coffee_app_test.inject.summary".
    implicit_dart_library = False,
    script_file = "test/coffee_app_test.dart",
    deps = [
        ":coffee",
        ":test",
        "//third_party/dart/inject",
        "//third_party/dart/test",
    ],
)

dart_library(
    name = "test",
    testonly = 1,
    srcs = [
        "test/coffee_app_test.dart",
    ],
    generate_for = [
        "test/coffee_app_test.dart",
    ],
    license_files = ["LICENSE"],
    deps = [
        ":coffee",
        "//third_party/dart/inject",
        "//third_party/dart/test",
    ],
)
