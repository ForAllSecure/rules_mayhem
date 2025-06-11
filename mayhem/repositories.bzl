load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

def rules_mayhem_archives():
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "platforms",
        sha256 = "3384eb1c30762704fbe38e440204e114154086c8fc8a8c2e3e28441028c019a8",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/platforms/releases/download/1.0.0/platforms-1.0.0.tar.gz",
            "https://github.com/bazelbuild/platforms/releases/download/1.0.0/platforms-1.0.0.tar.gz",
        ]
    )

def rules_mayhem_config(mayhem_url):
    """
    This function sets up the configuration for the Mayhem rules.

    Args:
        mayhem_url: The URL to the Mayhem platform.
    """

    

def rules_mayhem_repositories(mayhem_url = None):
    """
    This function sets up the repositories for the Mayhem rules.

    Args:
        mayhem_url: The URL to the Mayhem platform.
    """

    if not mayhem_url:
        mayhem_url = "https://app.mayhem.security"

    maybe(
        http_file,
        name = "mayhem_cli_linux",
        urls = [mayhem_url + "/cli/Linux/mayhem"],
        executable = True,
    )
    
    maybe(
        http_file,
        name = "mayhem_cli_windows",
        urls = [mayhem_url + "/cli/Windows/mayhem.exe"],
        executable = True,
    )

    # Need to figure out how to install a .pkg
    # http_file(
    #     name = "mayhem_cli_osx",
    #     urls = [mayhem_url + "/cli/Darwin/mayhem.pkg"],
    #     executable = False,
    # )

    maybe(
        http_file,
        name = "yq_cli_linux",
        urls = ["https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_linux_amd64"],
        sha256 = "b96de04645707e14a12f52c37e6266832e03c29e95b9b139cddcae7314466e69",
        executable = True,
    )
    
    maybe(
        http_file,
        name = "yq_cli_windows",
        urls = ["https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_windows_amd64.exe"],
        sha256 = "844df159573a42606139ff60f2e66b791c4c06413e89473e2af25e476459fb0e",
        executable = True,
    )

    # Will uncomment later when we have a better solution for macOS
    # maybe(
    #     http_file,
    #     name = "yq_cli_osx",
    #     urls = ["https://github.com/mikefarah/yq/releases/download/v4.45.4/yq_darwin_amd64"],
    #     sha256 = "5580ff2c1fc80dd91f248b3e19af2431f1c95767ad0949a60176601ca5140318",
    #     executable = True,
    # )

    rules_mayhem_archives()