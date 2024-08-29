load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])


# toolchain_type(
#     name = "mayhem_toolchain",
#     visibility = ["//visibility:public"],
# )

bzl_library(
    name = "mayhem",
    srcs = ["mayhem.bzl"],
)

# bzl_library(
#     name = "repositories",
#     srcs = ["repositories.bzl"],
# )

alias(
    name = "mayhem_cli",
    actual = select({
        "@platforms//os:linux": "@mayhem_cli_linux//file",
        "@platforms//os:windows": "@mayhem_cli_windows//file",
    }),
    visibility = ["//visibility:public"],
)

alias(
    name = "yq_cli",
    actual = select({
        "@platforms//os:linux": "@yq_cli_linux//file",
        "@platforms//os:windows": "@yq_cli_windows//file",
    }),
    visibility = ["//visibility:public"],
)