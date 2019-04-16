package(default_visibility = ["//visibility:public"])

load(
    "//dart:build_defs.bzl",
    "dart_library",
)

licenses(["notice"])  # New BSD

exports_files(["LICENSE"])

dart_library(
    name = "food",
    srcs = glob(["lib/**/*.dart"]),
    generate_for = [
        "lib/food.dart",
    ],
    license_files = ["LICENSE"],
    deps = [
        "//third_party/dart/inject",
        "//third_party/dart/inject/example/train/common",
    ],
)
