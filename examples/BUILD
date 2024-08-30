load("@rules_mayhem//mayhem:mayhem.bzl", "mayhemfile", "mayhem_run", "mayhem_package")
load("@aspect_bazel_lib//lib:yq.bzl", "yq")

# Generates a minimal Mayhemfile
mayhemfile(
    name = "factor_mayhemfile",
    project = "bazel-rules",
    target = "factor",
    cmd = "/bin/factor",
    image = "photon:latest",
)

# Generates a complete Mayhemfile
mayhemfile(
    name = "base64_mayhemfile",
    project = "bazel-rules",
    owner = "forallsecure-demo",
    target = "base64",
    cmd = "/bin/base64 @@",
    image = "photon:latest",
    duration = "90",
    advanced_triage = "false",
    uid = "0",
    gid = "0",
    max_length = "8192",
    cwd = "/bin",
    filepath = "/tmp/customfile",
    env = {"FOO": "foo", "BAR": "bar"},
    memory_limit = "8192",
    sanitizer = "false",
    libfuzzer = "false",
    honggfuzz = "false",
)

# Generates a network target Mayhemfile
mayhemfile(
    name = "lighttpd_mayhemfile",
    project = "bazel-rules",
    target = "lighttpd",
    cmd = "/usr/local/sbin/lighttpd -D -f /usr/local/etc/lighttpd.conf",
    image = "forallsecure/lighttpd:vulnerable",
    network_url = "tcp://localhost:80",
    network_timeout = "2",
    network_client = "false",
    duration = "120"
)

cc_binary(
    name = "mayhemit",
    srcs = ["mayhemit.c"],
)

# `mayhem_package` automatically generates a Mayhemfile; a separate mayhemfile rule is not needed
mayhem_package(
    name = "package_mayhemit",
    binary = ":mayhemit",
)

mayhem_run(
    name = "run_factor",
    target_path = ".",
    mayhemfile = ":factor_mayhemfile",
)

mayhem_run(
    name = "run_base64",
    target_path = ".",
    mayhemfile = ":base64_mayhemfile",
)

mayhem_run(
    name = "run_lighttpd",
    target_path = ".",
    mayhemfile = ":lighttpd_mayhemfile",
)

mayhem_run(
    name = "run_mayhemit",
    image = "ubuntu:latest",
    target_path = ":package_mayhemit"
)


sh_test(
    name = "validate_factor",
    srcs = ["//tests:mayhem_validator.sh"],
    args = [
        "$(location @rules_mayhem//mayhem:yq_cli)",
        "$(location :factor_mayhemfile)"
    ],
    data = [
        "@rules_mayhem//mayhem:yq_cli",
        ":factor_mayhemfile"
    ],
)

sh_test(
    name = "validate_base64",
    srcs = ["//tests:mayhem_validator.sh"],
    args = [
        "$(location @rules_mayhem//mayhem:yq_cli)",
        "$(location :base64_mayhemfile)"
    ],
    data = [
        "@rules_mayhem//mayhem:yq_cli",
        ":base64_mayhemfile"
    ],
)

sh_test(
    name = "validate_lighttpd",
    srcs = ["//tests:mayhem_validator.sh"],
    args = [
        "$(location @rules_mayhem//mayhem:yq_cli)",
        "$(location :lighttpd_mayhemfile)"
    ],
    data = [
        "@rules_mayhem//mayhem:yq_cli",
        ":lighttpd_mayhemfile"
    ],
)

sh_test(
    name = "validate_mayhemit",
    srcs = ["//tests:mayhem_validator.sh"],
    args = [
        "$(location @rules_mayhem//mayhem:yq_cli)",
        "$(location :package_mayhemit)"
    ],
    data = [
        "@rules_mayhem//mayhem:yq_cli",
        ":package_mayhemit"
    ],
)