load("//mayhem:mayhem.bzl", "mayhem")

# Generates a minimal Mayhemfile
mayhem(
    name = "factor",
    run = False,
    project = "bazel-rules",
    target = "factor",
    command = "/bin/factor",
    image = "photon:latest",
)

# Generates a complete Mayhemfile
mayhem(
    name = "base64",
    run = False,
    project = "bazel-rules",
    target = "base64",
    command = "/bin/base64 @@",
    second_command = "/bin/base64 -d @@", # just a duplicate in this example; in real life, you want to provide both an instrumented and uninstrumented target to take advantage of SE
    image = "photon:latest",
    duration = "90",
    tasks = [
      "exploitability_factors",
      "regression_testing",
      "behavior_testing"
    ],
    testsuite = [
      "file://testsuite" # or https://<server>/<owner>/<project_name>/<target_name>/testsuite.tar
    ],
    uid = "0",
    gid = "0",
    max_length = "8192",
    cwd = "/bin",
    filepath = "/tmp/customfile",
    env = {"FOO": "foo", "BAR": "bar"},
    cmd_timeout = "3",
    memory_limit = "8192",
    sanitizer = "false",
    libfuzzer = "false",
    afl = "false",
    honggfuzz = "false",
    dictionary = ""
)

# Generates a network target Mayhemfile
mayhem(
    name = "lighttpd",
    run = False,
    version = "2.0",
    project = "bazel-rules",
    target = "lighttpd",
    command = "/usr/local/sbin/lighttpd -D -f /usr/local/etc/lighttpd.conf",
    image = "forallsecure/lighttpd:vulnerable",
    network = [
      "url: tcp://localhost:80",
      "timeout: 2",
      "client: false"
    ],
    tasks = [
      "exploitability_factors",
      "regression_testing",
      "behavior_testing",
      "coverage_analysis"
    ],
    duration = "120"
)

sh_test(
    name = "validate_factor",
    srcs = ["//tests:mayhem_validator.sh"],
    args = [
        "$(location //:yq)",
        "$(location //:mayhem)",
        "$(location :factor.mayhemfile)"
    ],
    data = [
        "//:yq",
        "//:mayhem",
        ":factor.mayhemfile"
    ],
)

sh_test(
    name = "validate_base64",
    srcs = ["//tests:mayhem_validator.sh"],
    args = [
        "$(location //:yq)",
        "$(location //:mayhem)",
        "$(location :base64.mayhemfile)"
    ],
    data = [
        "//:yq",
        "//:mayhem",
        ":base64.mayhemfile"
    ],
)

sh_test(
    name = "validate_lighttpd",
    srcs = ["//tests:mayhem_validator.sh"],
    args = [
        "$(location //:yq)",
        "$(location //:mayhem)",
        "$(location :lighttpd.mayhemfile)"
    ],
    data = [
        "//:yq",
        "//:mayhem",
        ":lighttpd.mayhemfile"
    ],
)
