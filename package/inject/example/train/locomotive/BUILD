load(
    "//dart:build_defs.bzl",
    "dart_library",
    "dart_vm_test",
)

package(default_visibility = ["//visibility:public"])

licenses(["notice"])  # New BSD

exports_files(["LICENSE"])

dart_library(
    name = "locomotive",
    srcs = glob(["lib/**/*.dart"]),
    generate_for = [
        "lib/locomotive.dart",
    ],
    license_files = ["LICENSE"],
    deps = [
        "//third_party/dart/inject",
        "//third_party/dart/inject/example/train/bike",
        "//third_party/dart/inject/example/train/common",
        "//third_party/dart/inject/example/train/food",
    ],
)

dart_vm_test(
    name = "locomotive_test",
    script_file = "test/locomotive_test.dart",
    deps = [
        ":locomotive",
        "//third_party/dart/inject/example/train/bike",
        "//third_party/dart/inject/example/train/common",
        "//third_party/dart/inject/example/train/food",
        "//third_party/dart/test",
    ],
)
