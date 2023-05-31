load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

bzl_library(
    name = "mayhem_file",
    srcs = ["mayhem.bzl"],
)

bzl_library(
    name = "mayhem_run",
    srcs = ["mayhem.bzl"],
)

bzl_library(
    name = "mayhem_validator",
    srcs = ["mayhem_validation.bzl"],
)

exports_files(["mayhemfile.template"])
