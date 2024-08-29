package(default_visibility = ["//visibility:public"])
licenses(["notice"])
exports_files(["LICENSE"])

filegroup(
    name = "distribution",
    srcs = [
        "BUILD",
        "LICENSE",
    ],
    visibility = ["@//distro:__pkg__"],
)

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