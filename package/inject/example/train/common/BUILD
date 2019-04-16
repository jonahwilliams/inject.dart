package(default_visibility = ["//visibility:public"])

load(
    "//dart:build_defs.bzl",
    "dart_library",
)

licenses(["notice"])  # New BSD

exports_files(["LICENSE"])

dart_library(
    name = "common",
    srcs = glob(["lib/**/*.dart"]),
    generate_for = [
        "lib/common.dart",
    ],
    license_files = ["LICENSE"],
    deps = [
        "//third_party/dart/inject",
    ],
)
