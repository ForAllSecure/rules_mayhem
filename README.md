# rules_mayhem

Generates a Mayhemfile and kicks off a Mayhem run.

## To include

You can add the following snippet:

```
## MODULE.bazel
bazel_dep(name = "rules_mayhem", version = "0.7.0")
```
> *Note: Please see the latest release notes for instructions on how to include the latest release of rules_mayhem into your environment.*

### Pre-requisites

You'll need to modify your `.bazelrc` to use `--spawn-strategy=standalone`. 

```
# Enable bzlmod
common --enable_bzlmod

# Define MAYHEM_URL - you can (and should!) change this if you have your own instance
build --define=MAYHEM_URL=app.mayhem.security

# Spawn strategy - if this is not set, bazel tries to reference files that don't exist
build --spawn_strategy=standalone
```

Or, you can pass it to bazel directly, with `bazel build --spawn-strategy=standalone [...]`


## To build a Mayhemfile

Create a BUILD file:
```                                                                                                                                                              
load("//mayhem:mayhem.bzl", "mayhemfile", "mayhem_run", "mayhem_package")

# Generates a minimal Mayhemfile
mayhemfile(
    name = "factor_mayhemfile",
    project = "bazel-rules",
    target = "factor",
    cmd = "/bin/factor",
    image = "photon:latest",
)
```

Run `bazel build`
```
$ bazel build //examples:factor_mayhemfile

INFO: Analyzed target //examples:factor_mayhemfile (0 packages loaded, 1 target configured).
INFO: Found 1 target...
Target //examples:factor_mayhemfile up-to-date:
  bazel-bin/examples/factor_mayhemfile.mayhemfile
INFO: Elapsed time: 0.128s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
```

Should produce valid Mayhemfile:
```
$ cat bazel-out/k8-fastbuild/bin/examples/factor_mayhemfile.mayhemfile

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
extensions: {}

    ## Uncomment to change default dir (/) from which the target is invoked
    #cwd: /

    ## If this is a network target, uncomment the block below and remove
    ## the @@ input file reference in the cmd (you can either test network or
    ## file inputs, not both).
    #network:
    ## Use "127.0.0.1" instead of "localhost" below if you want to test only
    ## for IPv4. For IPv6, use "[::1]". By leaving as "localhost", Mayhem will
    ## attempt to autodetect the one used by the target.
    #  url: tcp://localhost:8080  # protocol, host and port to analyze
    #  client: False           # target is a client-side program
    #  timeout: 2.0               # max seconds for sending data

    ## Max test case length (in bytes) to be taken into account. Test cases over
    ## that length will be truncated. Be very careful about increasing this
    ## limit as it can severely affect your fuzzer performance.
    # max_length: 8192

```
## To run a mayhemfile

Use `mayhem_run`

```
mayhem_run(
    name = "run_factor",
    target_path = ".",
    mayhemfile = ":factor_mayhemfile",
)
```

Then build:

```
bazel build //examples:run_factor
INFO: Analyzed target //examples:run_factor (0 packages loaded, 0 targets configured).
INFO: From Starting Mayhem run from 'examples':
WARNING /home/xansec/mayhem/github/mcode/rules_mayhem/examples/testsuite is not a file or directory, skipping
git version 2.46.0 found
WARNING A default branch has not been configured for this target. Job differences will not be available in this report
Run started: bazel-rules/factor/9
Run URL: https://app.mayhem.security:443/xansec/bazel-rules/factor/9
INFO: Found 1 target...
Target //examples:run_factor up-to-date:
  bazel-bin/examples/run_factor.mayhem_out
INFO: Elapsed time: 22.883s, Critical Path: 22.75s
INFO: 2 processes: 1 internal, 1 local.
INFO: Build completed successfully, 2 total actions
```

## Packaging binaries

`rules_mayhem` also supports the package workflow. In your BUILD file:

```
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
    name = "run_mayhemit",
    image = "ubuntu:latest", # or whatever base image your binary should run on; by default, we use debian-buster
    target_path = ":package_mayhemit"
)
```

Then build and run:

```
bazel build //examples:mayhemit
INFO: Analyzed target //examples:mayhemit (1 packages loaded, 7 targets configured).
INFO: Found 1 target...
Target //examples:mayhemit up-to-date:
  bazel-bin/examples/mayhemit
INFO: Elapsed time: 0.347s, Critical Path: 0.09s
INFO: 7 processes: 5 internal, 2 local.
INFO: Build completed successfully, 7 total actions


bazel build //examples:package_mayhemit
INFO: Analyzed target //examples:package_mayhemit (0 packages loaded, 1 target configured).
INFO: From Packaging target examples/mayhemit to 'bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg'...:
Generating default configuration under: bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg/Mayhemfile
Packaging complete.
To upload the package do: `mayhem run bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg`.
Before uploading, you may wish to edit the config file at 'bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg/Mayhemfile'.
bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg
INFO: Found 1 target...
Target //examples:package_mayhemit up-to-date:
  bazel-bin/examples/mayhemit-pkg
INFO: Elapsed time: 3.488s, Critical Path: 3.43s
INFO: 2 processes: 1 internal, 1 local.
INFO: Build completed successfully, 2 total actions


bazel build --action_env=MAYHEM_URL=$MAYHEM_URL --action_env=MAYHEM_TOKEN=$MAYHEM_TOKEN //examples:run_mayhemit
INFO: Analyzed target //examples:run_mayhemit (0 packages loaded, 1 target configured).
INFO: From Starting Mayhem run from 'bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg':
git version 2.46.0 found
WARNING A default branch has not been configured for this target. Job differences will not be available in this report
/tmp/tmp1rd5ih1v/root.tgz   0% |                     | ETA:  --:--:--   0.0 s/B
/tmp/tmp1rd5ih1v/root.tgz 100% |###################| Time:  0:00:00   9.3 KiB/s
Run started: mayhemit/mayhemit/11
Run URL: https://app.mayhem.security:443/xansec/mayhemit/mayhemit/11
INFO: Found 1 target...
Target //examples:run_mayhemit up-to-date:
  bazel-bin/examples/run_mayhemit.mayhem_out
INFO: Elapsed time: 6.567s, Critical Path: 6.50s
INFO: 3 processes: 2 internal, 1 local.
INFO: Build completed successfully, 3 total actions
```

# To Do

- Customizeable Mayhem CLI download URL
- Combine the `mayhem_run` targets into the `mayhemfile` and `mayhem_package` targets and execute with `bazel run`
- Use output flag for `mayhem run` instead of custom wrapper script
- Tests are currently `sh_test` only and do not run on Windows