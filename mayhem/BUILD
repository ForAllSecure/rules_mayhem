load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

bzl_library(
    name = "mayhem",
    srcs = ["mayhem.bzl"],
)

bzl_library(
    name = "repositories",
    srcs = ["repositories.bzl"],
)

config_setting(
    name = "is_linux_x64",
    constraint_values = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
)

config_setting(
    name = "is_windows_x64",
    constraint_values = [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
)

config_setting(
    name = "is_osx_x64",
    constraint_values = [
        "@platforms//os:osx",
        "@platforms//cpu:x86_64",
    ],
)

alias(
    name = "mayhem_cli",
    actual = select({
        ":is_linux_x64": "@mayhem_cli_linux//file",
        ":is_windows_x64": "@mayhem_cli_windows//file",
        # ":is_osx_x64": "@mayhem_cli_osx//file",
        "//conditions:default": "@platforms//:incompatible",
    }),
    visibility = ["//visibility:public"],
)

alias(
    name = "yq_cli",
    actual = select({
        ":is_linux_x64": "@yq_cli_linux//file",
        ":is_windows_x64": "@yq_cli_windows//file",
        ":is_osx_x64": "@yq_cli_osx//file",
        "//conditions:default": "@platforms//:incompatible",
    }),
    visibility = ["//visibility:public"],
)