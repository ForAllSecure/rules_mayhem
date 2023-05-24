load("//mayhem:mayhem.bzl", "mayhemfile")

# Generates a minimal Mayhemfile
mayhemfile(
    name = "factor",
    project = "bazel_rules",
    target = "factor",
    command = "/bin/factor",
    image = "ubuntu:latest"
)


# Generates a complete Mayhemfile
mayhemfile(
    name = "b2sum",
    project = "bazel_rules",
    target = "b2sum",
    command = "./b2sum --status --ignore-missing @@",
    second_command = "./uninst/b2sum --status --ignore-missing @@", # just a duplicate in this example; in real life, you want to provide both an instrumented and uninstrumented target to take advantage of SE
    image = "ubuntu:latest",
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
mayhemfile(
    name = "lighttpd",
    version = "2.0",
    project = "bazel_rules",
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
