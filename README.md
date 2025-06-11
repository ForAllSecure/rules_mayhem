# rules_mayhem

Run Mayhem from your Bazel infrastructure.

## To include

You can add the following snippet:

```
## MODULE.bazel
bazel_dep(name = "rules_mayhem", version = "0.7.8")

rules_mayhem_extension = use_extension("@rules_mayhem//mayhem:extensions.bzl", "rules_mayhem_extension")
use_repo(rules_mayhem_extension, "bazel_skylib", "mayhem_cli_linux", "mayhem_cli_windows", "platforms", "yq_cli_linux", "yq_cli_osx", "yq_cli_windows")
```

```
## WORKSPACE
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_mayhem",
    strip_prefix = "rules_mayhem",
    urls = ["https://github.com/ForAllSecure/rules_mayhem/releases/download/0.7.8/rules_mayhem-0.7.8.tar.gz"],
    sha256 = "dea38cb85e6e98892c6c1399227ea08407db9570abe704aa4ff10b11350e5a20",
)

load("@rules_mayhem//mayhem:repositories.bzl", "rules_mayhem_repositories")
rules_mayhem_repositories()
```

> *Note: Please see the latest release notes for instructions on how to include the latest release of rules_mayhem into your environment.*

### Pre-requisites

You'll need to modify your `.bazelrc` to use `--spawn-strategy=standalone`. 

```
# Enable bzlmod
common --enable_bzlmod

# Spawn strategy - if this is not set, bazel tries to reference files that don't exist
build --spawn_strategy=standalone
```

### Mayhem Secrets

Mayhem secrets, such as URL and token, are required to run Mayhem. Users should set these values in a secrets file, called `mayhem_secrets.bzl`, in the root of their Bazel workspace. The file should look like this:

```starlark
mayhem_url="https://app.mayhem.security"
mayhem_token="AT1.<secret content>"
```

Make sure you add this file to your `.gitignore` so that it is not checked into version control.

## To build a Mayhemfile

Create a BUILD file:
```                                                                                                                                                              
load("//mayhem:mayhem.bzl", "mayhem_init", "mayhem_run", "mayhem_package")

# Generates a minimal Mayhemfile
mayhem_init(
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

This should produce a valid Mayhemfile:
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
git version 2.46.0 found
WARNING A default branch has not been configured for this target. Job differences will not be available in this report
Run started: forallsecure-demo/bazel-rules/factor/9
Run URL: https://app.mayhem.security:443/forallsecure-demo/bazel-rules/factor/9
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


bazel build //examples:run_mayhemit
INFO: Analyzed target //examples:run_mayhemit (0 packages loaded, 1 target configured).
INFO: From Starting Mayhem run from 'bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg':
git version 2.46.0 found
WARNING A default branch has not been configured for this target. Job differences will not be available in this report
/tmp/tmp1rd5ih1v/root.tgz   0% |                     | ETA:  --:--:--   0.0 s/B
/tmp/tmp1rd5ih1v/root.tgz 100% |###################| Time:  0:00:00   9.3 KiB/s
Run started: forallsecure-demo/bazel-rules/mayhemit/11
Run URL: https://app.mayhem.security:443/forallsecure-demo/bazel-rules/mayhemit/11
INFO: Found 1 target...
Target //examples:run_mayhemit up-to-date:
  bazel-bin/examples/run_mayhemit.mayhem_out
INFO: Elapsed time: 6.567s, Critical Path: 6.50s
INFO: 3 processes: 2 internal, 1 local.
INFO: Build completed successfully, 3 total actions
```

## Waiting and run reports

You can wait on a Mayhem run by adding the `wait = True` parameter to `mayhem_run()`:

```
mayhem_run(
    name = "run_mayhemit",
    image = "ubuntu:latest",
    target_path = ":package_mayhemit",
    wait = True,
)
```

You can tell Mayhem to return exit code 1 if defects are found. You can also specify to return either a JUnit or SARIF report:
```
mayhem_run(
    name = "run_mayhemit",
    image = "ubuntu:latest",
    target_path = ":package_mayhemit",
    wait = True,
    fail_on_defects = True,
    sarif = mayhemit.sarif,
    junit = mayhemit.junit,
)
```

Then build and run:

```
bazel build //examples:run_mayhemit
INFO: Analyzed target //examples:run_mayhemit (56 packages loaded, 239 targets configured).
INFO: From Packaging target examples/mayhemit to 'bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg'...:
Packaging target: examples/mayhemit
Packaging dependency: examples/mayhemit -> bazel-out/k8-fastbuild/bin/examples/mayhemit
Generating default configuration under: bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg/Mayhemfile
Packaging complete.
To upload the package do: `mayhem run bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg`.
Before uploading, you may wish to edit the config file at 'bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg/Mayhemfile'.
bazel-out/k8-fastbuild/bin/examples/mayhemit-pkg
INFO: From Starting Mayhem run...:
git version 2.46.1 found
WARNING A default branch has not been configured for this target. Job differences will not be available in this report
/tmp/tmpz6srnoug/root.tgz   0% |                     | ETA:  --:--:--   0.0 s/B
/tmp/tmpz6srnoug/root.tgz 100% |###################| Time:  0:00:00   6.1 KiB/s
Run started: bazel-rules/mayhemit/9
Run URL: https://app.mayhem.security:443/forallsecure-demo/bazel-rules/mayhemit/9
INFO: From Waiting for Mayhem run to complete...:
Generating JUnit XML report: mayhemit_junit.xml
  Processing run forallsecure-demo/bazel-rules/mayhemit/9
    Downloading testcase reports...
    Processing 13 testcase reports...
Writing JUnit report to mayhemit_junit.xml
Generating SARIF JSON report: mayhemit_sarif.json
  Processing run forallsecure-demo/bazel-rules/mayhemit/9
    Downloading defect reports...
    Processing 1 defect reports...
Writing SARIF report to mayhemit_sarif.json
ERROR Run completed, defects found
Suggestion: Please review the generated testcase reports and correct the identified defects.
Statistics for forallsecure-demo/bazel-rules/mayhemit/9
    Status: coverage_analysis:running, dynamic_analysis:completed, regression_testing:completed, static_analysis:completed
    Run started: Fri Oct 11 14:46:19 2024 -0400
    Time elapsed: 0:01:14
    Tests performed: 24610
    Test reports: 13
    Crash reports: 1
    Defects: 1
INFO: Found 1 target...
Target //examples:run_mayhemit up-to-date:
  bazel-bin/examples/run_mayhemit.out
  bazel-bin/examples/run_mayhemit.wait.out
INFO: Elapsed time: 87.843s, Critical Path: 87.58s
INFO: 9 processes: 4 internal, 5 local.
INFO: Build completed successfully, 9 total actions
```

## Downloading testsuite and coverage information

`rules_mayhem` supports downloading testsuite and coverage information. In your BUILD file:

```
mayhem_download(
    name = "download_mayhemit",
    owner = "forallsecure-demo",
    project = "bazel-rules",
    target = "mayhemit",
    output_dir = "mayhemit_output",
)
```

Then build and run:

```
bazel build //examples:download_mayhemit
INFO: Analyzed target //examples:download_mayhemit (6 packages loaded, 15 targets configured).
INFO: From Downloading Mayhem artifacts for download_mayhemit...:
Downloading target data from run forallsecure-demo/bazel-rules/mayhemit/5...
Downloaded: Mayhemfile.
Downloaded: root.tgz.
Downloaded: coverage.tgz.
Downloading testsuite.tar:   0.0 B |#         | Elapsed Time: 0:00:00   0.0 s/B
Downloading testsuite.tar:   8.0 KiB |     #| Elapsed Time: 0:00:01   4.4 KiB/s
Downloading testsuite.tar:  33.0 KiB |     #| Elapsed Time: 0:00:01  17.7 KiB/s
Extracting tests 0 of 23 |                                     | ETA:  --:--:--
Extracting tests 23 of 23 |####################################| Time:  0:00:00
Target downloaded at: 'bazel-out/k8-fastbuild/bin/examples/mayhemit_output'.
INFO: Found 1 target...
Target //examples:download_mayhemit up-to-date:
  bazel-bin/examples/mayhemit_output
INFO: Elapsed time: 6.615s, Critical Path: 6.43s
INFO: 2 processes: 1 internal, 1 local.
INFO: Build completed successfully, 2 total actions
```

# To Do

- [x] Customizeable Mayhem CLI download URL
- [x] Support for packaging binaries
- [x] `wait` parameter to `mayhem_run()`: Support waiting for Mayhem run to complete
- [x] `fail_on_defects` parameter to `mayhem_run()`: Return exit code 1 if Mayhem run finds defects
- [x] `mayhem_download` rule to grab testsuite and coverage info
- [x] Remove support for using `--action_env` to set Mayhem secrets (this is leaky); use a `mayhem_secrets.bzl` file instead 
- [ ] Support MacOS (currently only Linux and Windows; MacOS requires binary signing and unpackaging)
- [ ] Run the `mayhem_run` targets with `bazel run` instead of `bazel build`
- [ ] Use output flag for `mayhem run` instead of custom wrapper script
- [ ] Tests are currently `sh_test` only and do not run on Windows

If you want to help any of the above, feel free to open a PR!
