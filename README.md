# rules_mayhemfile

Generates a Mayhemfile.

## To include

You can add the following snippet:

```
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_mayhemfile",
    urls = ["https://github.com/xansec/rules_mayhemfile/releases/download/0.1/rules_mayhemfile-0.1.tar.gz"],
    sha256 = "b8a1527901774180afc798aeb28c4634bdccf19c4d98e7bdd1ce79d1fe9aaad7",
)
load("@rules_mayhemfile//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")
load("@rules_mayhemfile//mayhemfile:mayhemfile.bzl", "mayhemfile")
```
