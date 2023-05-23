# rules_mayhemfile

Generates a Mayhemfile.

## To include

You can add the following snippet:

```
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_mayhemfile",
    urls = ["https://github.com/xansec/rules_mayhemfile/releases/download/0.1/rules_mayhemfile-0.1.tar.gz"],
    sha256 = "123",
)
load("@rules_mayhemfile//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")
load("@rules_mayhemfile//mayhemfile:mayhemfile.bzl", "mayhemfile")
```
# To run example

Create a BUILD file:
```
$ cat examples/BUILD                                                                                                                                                                  
load("//mayhemfile:mayhemfile.bzl", "mayhemfile")

# Generates a minimal Mayhemfile
mayhemfile(
    name = "factor",
    project = "bazel_rules",
    target = "factor",
    command = "/bin/factor",
    image = "ubuntu:latest"
)
```

Run `bazel build`
```
$ bazel build //examples:factor                                                                                                                                                       
INFO: Analyzed target //examples:factor (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //examples:factor up-to-date:
  bazel-bin/examples/factor.mayhemfile
INFO: Elapsed time: 0.040s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
```

Should produce valid Mayhemfile:
```
$ cat bazel-out/k8-fastbuild/bin/examples/factor.mayhemfile                                                                                                                            
# Mayhem by https://forallsecure.com
# Mayhemfile: configuration file for testing your target with Mayhem
# Format: YAML 1.1


# Project name that the target belongs to
project: bazel_rules

# Target name (should be unique within the project)
target: factor

# Base image to run the binary in.
image: ubuntu:latest

# Turns on extra test case processing (completing a run will take longer)
advanced_triage: false






# List of commands used to test the target
cmds:

  # Command used to start the target, "@@" is the input file
  # (when "@@" is omitted Mayhem defaults to stdin inputs)
  - cmd: /bin/factor
    env: {}








    ## Use "127.0.0.1" instead of "localhost" below if you want to test only
    ## for IPv4. For IPv6, use "[::1]". By leaving as "localhost", Mayhem will
    ## attempt to autodetect the one used by the target.


    ## Max test case length (in bytes) to be taken into account. Test cases over
    ## that length will be truncated. Be very careful about increasing this
    ## limit as it can severely affect your fuzzer performance.
