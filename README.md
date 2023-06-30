# rules_mayhem

Generates a Mayhemfile and kicks off a Mayhem run.

## To include

You can add the following snippet:

```
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_mayhem",
    urls = ["https://github.com/ForAllSecure/rules_mayhem/archive/rules_mayhem-0.5.tar.gz"],
    sha256 = "c3c6f022fc7a7d7f1f7a23475742e626c5274fe3a75f1ef2ebac7455805c5712",
)
load("@rules_mayhem//mayhem:mayhem.bzl", "mayhem")
```
## To build a Mayhemfile

Create a BUILD file:
```                                                                                                                                                              
load("//mayhem:mayhem.bzl", "mayhem")

# Generates a minimal Mayhemfile
mayhem(
    name = "factor",
    run = False,
    project = "bazel-rules",
    target = "factor",
    command = "/bin/factor",
    image = "photon:latest"
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
project: bazel-rules

# Target name (should be unique within the project)
target: factor

# Base image to run the binary in.
image: photon:latest

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
```
## To run a mayhemfile

Just set `run = True`:

```
mayhem(
    name = "factor",
    run = True,
    project = "bazel-rules",
    target = "factor",
    command = "/bin/factor",
    image = "photon:latest"
)
```

Then build:

```
bazel build //examples:factor
INFO: Analyzed target //examples:factor (5 packages loaded, 7 targets configured).
INFO: Found 1 target...
INFO: From Starting Mayhem run from examples/factor.mayhemfile...:
WARNING: testsuite is not a file or directory, skipping
Run started: bazel-rules/factor/4
Run URL: https://app.mayhem.security:443/username/bazel-rules/factor/1
Target //examples:factor up-to-date:
  bazel-bin/examples/factor.mayhemfile.out
INFO: Elapsed time: 5.343s, Critical Path: 5.21s
INFO: 3 processes: 2 internal, 1 linux-sandbox.
INFO: Build completed successfully, 3 total actions
```
