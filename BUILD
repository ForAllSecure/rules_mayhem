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

sh_binary(
    name = "yq",
    srcs = ["@yq_bin//file"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "mayhem",
    srcs = ["@mayhem_bin//file"],
    visibility = ["//visibility:public"],
)