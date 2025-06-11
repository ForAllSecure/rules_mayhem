load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("//:mayhem_secrets.bzl", "mayhem_url", "mayhem_token")


def _mayhem_init_impl(ctx):
    print("WARNING: The 'mayhem_init' rule is deprecated and will be removed in a future release. Please use 'mayhem_run' instead.")
    # Note: plan is to deprecate this in the future, but tests currently depend on validating output Mayhemfiles, so keeping it for now
    mayhemfile = ctx.actions.declare_file(ctx.label.name + ".mayhemfile")
    mayhem_cli = ctx.executable._mayhem_cli

    if ctx.attr.owner:
        full_project = ctx.attr.owner + "/" + ctx.attr.project
    else:
        full_project = ctx.attr.project

    args = ctx.actions.args()
    args.add("init")
    args.add("-o", mayhemfile.path)
    args.add("--project", full_project)
    args.add("--target", ctx.attr.target)
    args.add("--cmd", ctx.attr.cmd)    

    if ctx.attr.image:
        args.add("--image", ctx.attr.image)
    if ctx.attr.duration:
        args.add("--duration", ctx.attr.duration)
    if ctx.attr.uid:
        args.add("--uid", ctx.attr.uid)
    if ctx.attr.gid:
        args.add("--gid", ctx.attr.gid)
    if ctx.attr.advanced_triage:
        args.add("--advanced-triage", ctx.attr.advanced_triage)
    if ctx.attr.cwd:
        args.add("--cwd", ctx.attr.cwd)
    if ctx.attr.filepath:
        args.add("--filepath", ctx.attr.filepath)
    if ctx.attr.env:
        for key, value in ctx.attr.env.items():
            args.add("--env", key + "=" + value)
    if ctx.attr.network_url:
        args.add("--network-url", ctx.attr.network_url)
    if ctx.attr.network_timeout:
        args.add("--network-timeout", ctx.attr.network_timeout)
    if ctx.attr.network_client == "true":
        args.add("--network-client", ctx.attr.network_client)
    if ctx.attr.libfuzzer == "true":
        args.add("--libfuzzer", ctx.attr.libfuzzer)
    if ctx.attr.honggfuzz == "true":
        args.add("--honggfuzz", ctx.attr.honggfuzz)
    if ctx.attr.sanitizer == "true":
        args.add("--sanitizer", ctx.attr.sanitizer)
    if ctx.attr.max_length:
        args.add("--max-length", ctx.attr.max_length)
    if ctx.attr.memory_limit:
        args.add("--memory-limit", ctx.attr.memory_limit)

    ctx.actions.run(
        outputs = [mayhemfile],
        executable = mayhem_cli,
        progress_message = "Generating Mayhemfile for %s..." % ctx.label.name,
        arguments = [args],
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(
            files = depset([mayhemfile]),
        ),
    ]

mayhem_init = rule(
    implementation = _mayhem_init_impl,
    attrs = {
        "project": attr.string(mandatory = True),
        "target": attr.string(mandatory = True),
        "cmd": attr.string(mandatory = True),
        "owner": attr.string(mandatory = False),
        "image": attr.string(mandatory = False),
        "duration": attr.string(mandatory = False),
        "advanced_triage": attr.string(mandatory = False),
        "uid": attr.string(mandatory = False),
        "gid": attr.string(mandatory = False),
        "cwd": attr.string(mandatory = False),
        "filepath": attr.string(mandatory = False),
        "env": attr.string_dict(mandatory = False),
        "network_url": attr.string(mandatory = False),
        "network_timeout": attr.string(mandatory = False),
        "network_client": attr.string(mandatory = False),
        "libfuzzer": attr.string(mandatory = False),
        "honggfuzz": attr.string(mandatory = False),
        "sanitizer": attr.string(mandatory = False),
        "max_length": attr.string(mandatory = False),
        "memory_limit": attr.string(mandatory = False),
        "_mayhem_cli": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("@rules_mayhem//mayhem:mayhem_cli"),
            allow_single_file = True,
        ),
    },
)

def mayhem_login(ctx, mayhem_cli, mayhem_cli_exe, is_windows):
    """ Logs into Mayhem 
    
    Args:
        ctx: The context
        mayhem_cli: The path to the Mayhem CLI
        mayhem_cli_exe: (Optional) The path to the Mayhem CLI with .exe extension, or None if we are on Linux
        is_windows: A boolean indicating if the OS is Windows
    Returns:
        mayhem_login_out: The Mayhem login output file
    """
    env = dicts.add(ctx.configuration.default_shell_env, 
            {"MAYHEM_URL": mayhem_url}, 
            {"MAYHEM_TOKEN": mayhem_token}
        )

    mayhem_login_out = ctx.actions.declare_file(ctx.label.name + "-login.out")

    if is_windows:
        login_wrapper = ctx.actions.declare_file(ctx.label.name + "-login.bat")
        login_wrapper_content = """
        @echo off
        setlocal
        {mayhem_cli} login > {output_file}
        """.format(
            mayhem_cli=mayhem_cli_exe.path.replace("/", "\\"),
            output_file=mayhem_login_out.path.replace("/", "\\"),
        )
    else:
        login_wrapper = ctx.actions.declare_file(ctx.label.name + "-login.sh")
        login_wrapper_content = """
        #!/bin/bash
        {mayhem_cli} login > {output_file}
        """.format(
            mayhem_cli=mayhem_cli.path,
            output_file=mayhem_login_out.path,
        )

    ctx.actions.write(
        output=login_wrapper,
        content=login_wrapper_content
    )

    inputs = [mayhem_cli, login_wrapper]

    ctx.actions.run(
        inputs = inputs,
        outputs = [mayhem_login_out],
        executable = login_wrapper,
        progress_message = "Logging into Mayhem...",
        env = env,
    )

    return mayhem_login_out



def mayhem_wait(ctx, mayhem_cli, mayhem_cli_exe, mayhem_out, is_windows, junit, sarif, fail_on_defects):
    """ Waits for Mayhem to finish
    
    Args:
        ctx: The context
        mayhem_cli: The path to the Mayhem CLI
        mayhem_cli_exe: (Optional) The path to the Mayhem CLI with .exe extension, or None if we are on Linux
        mayhem_out: The Mayhem output file
        is_windows: A boolean indicating if the OS is Windows
        junit: The JUnit output file
        sarif: The SARIF output file
        fail_on_defects: A boolean indicating if the build should fail on defects

    Returns:
        mayhem_wait_out: The Mayhem wait output file
    """
    mayhem_wait_out = ctx.actions.declare_file(ctx.label.name + ".wait.out")

    junit = "--junit " + junit if junit else ""
    sarif = "--sarif " + sarif if sarif else ""
    fod = "--fail-on-defects" if fail_on_defects else ""
    opts = " ".join([junit, sarif, fod])

    if is_windows:
        wait_wrapper = ctx.actions.declare_file(ctx.label.name + "-wait.bat")
        wait_wrapper_content = """
        @echo off
        setlocal
        for /f "tokens=*" %%i in ({input_file}) do (
            {mayhem_cli} wait {opts} "%%i" >> {output_file}
            {mayhem_cli} show "%%i" >> {output_file}
            {mayhem_cli} show "%%i"
        )
        """.format(
            mayhem_cli=mayhem_cli_exe.path.replace("/", "\\"),
            input_file=mayhem_out.path.replace("/", "\\"),
            opts=opts,
            output_file=mayhem_wait_out.path.replace("/", "\\"),
        )
    else:
        wait_wrapper = ctx.actions.declare_file(ctx.label.name + "-wait.sh")
        wait_wrapper_content = """
        #!/bin/bash
        {mayhem_cli} wait {opts} $(cat {input_file}) > {output_file}
        {mayhem_cli} show $(cat {input_file}) | tee -a {output_file}
        """.format(
            mayhem_cli=mayhem_cli.path,
            input_file=mayhem_out.path,
            opts=opts,
            output_file=mayhem_wait_out.path,
        )

    ctx.actions.write(
        output=wait_wrapper,
        content=wait_wrapper_content
    )

    inputs = [mayhem_cli, mayhem_out, wait_wrapper]

    ctx.actions.run(
        inputs = inputs,
        outputs = [mayhem_wait_out],
        executable = wait_wrapper,
        progress_message = "Waiting for Mayhem run to complete...",
        use_default_shell_env = True,
    )

    return mayhem_wait_out

def _mayhem_run_impl(ctx):
    inputs = []
    mayhem_out = ctx.actions.declare_file(ctx.label.name + ".out")
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    args_list = []
    args_list.append("run")

    if ctx.file.mayhemfile:
        args_list.append(".")
        args_list.append("-f")
        args_list.append(ctx.file.mayhemfile.path)
        inputs.append(ctx.file.mayhemfile)
    elif ctx.file.target_path:
        args_list.append(ctx.file.target_path.path)
        args_list.append("-f")
        args_list.append(ctx.file.target_path.path + "/Mayhemfile")
        inputs.append(ctx.file.target_path)
    elif ctx.attr.image:
        args_list.append(ctx.attr.image)
        args_list.append("--docker")
    else:
        fail("Either mayhemfile, image or target_path must be set")

    if ctx.attr.regression:
        args_list.append("--regression")
    if ctx.attr.static:
        args_list.append("--static")
    if ctx.attr.dynamic:
        args_list.append("--dynamic")
    if ctx.attr.coverage:
        args_list.append("--coverage")
    if ctx.attr.all:
        args_list.append("--all")
    if ctx.attr.owner:
        args_list.append("--owner")
        args_list.append(ctx.attr.owner)
    if ctx.attr.project:
        args_list.append("--project")
        args_list.append(ctx.attr.project)
    if ctx.attr.target:
        args_list.append("--target")
        args_list.append(ctx.attr.target)
    if ctx.attr.cmd:
        args_list.append("--cmd")
        args_list.append("'{}'".format(ctx.attr.cmd))
    if ctx.attr.image:
        args_list.append("--image")
        args_list.append(ctx.attr.image)
    if ctx.attr.duration:
        args_list.append("--duration")
        args_list.append(ctx.attr.duration)
    if ctx.attr.warning_as_error:
        args_list.append("--warning-as-error")
    if ctx.attr.ci_url:
        args_list.append("--ci-url")
        args_list.append(ctx.attr.ci_url)
    if ctx.attr.merge_base_branch_name:
        args_list.append("--merge-base-branch-name")
        args_list.append(ctx.attr.merge_base_branch_name)
    if ctx.attr.branch_name:
        args_list.append("--branch-name")
        args_list.append(ctx.attr.branch_name)
    if ctx.attr.revision:
        args_list.append("--revision")
        args_list.append(ctx.attr.revision)
    if ctx.attr.parent_revision:
        args_list.append("--parent-revision")
        args_list.append(ctx.attr.parent_revision)
    if ctx.attr.scm_remote:
        args_list.append("--scm-remote")
        args_list.append(ctx.attr.scm_remote)
    if ctx.attr.uid:
        args_list.append("--uid")
        args_list.append(ctx.attr.uid)
    if ctx.attr.gid:
        args_list.append("--gid")
        args_list.append(ctx.attr.gid)
    if ctx.attr.advanced_triage:
        args_list.append("--advanced-triage")
        args_list.append(ctx.attr.advanced_triage)
    if ctx.attr.cwd:
        args_list.append("--cwd")
        args_list.append(ctx.attr.cwd)
    if ctx.attr.filepath:
        args_list.append("--filepath")
        args_list.append(ctx.attr.filepath)
    if ctx.attr.env:
        for key, value in ctx.attr.env.items():
            args_list.append("--env")
            args_list.append(key + "=" + value)
    if ctx.attr.network_url:
        args_list.append("--network-url")
        args_list.append(ctx.attr.network_url)
    if ctx.attr.network_timeout:
        args_list.append("--network-timeout")
        args_list.append(ctx.attr.network_timeout)
    if ctx.attr.network_client == "true":
        args_list.append("--network-client")
        args_list.append(ctx.attr.network_client)
    if ctx.attr.libfuzzer == "true":
        args_list.append("--libfuzzer")
        args_list.append(ctx.attr.libfuzzer)
    if ctx.attr.honggfuzz == "true":
        args_list.append("--honggfuzz")
        args_list.append(ctx.attr.honggfuzz)
    if ctx.attr.sanitizer == "true":
        args_list.append("--sanitizer")
        args_list.append(ctx.attr.sanitizer)
    if ctx.attr.max_length:
        args_list.append("--max-length")
        args_list.append(ctx.attr.max_length)
    if ctx.attr.memory_limit:
        args_list.append("--memory-limit")
        args_list.append(ctx.attr.memory_limit)
    if ctx.attr.testsuite:
        args_list.append("--testsuite")
        args_list.append(ctx.attr.testsuite)

    # For self-signed instances
    if ctx.attr.insecure:
        args_list.append("--insecure")

    if is_windows:
        # Need to copy the Mayhem CLI to have .exe extension
        mayhem_cli_exe = ctx.actions.declare_file(ctx.executable._mayhem_cli.path + ".exe")

        ctx.actions.symlink(
            output = mayhem_cli_exe,
            target_file = ctx.executable._mayhem_cli,
            is_executable = True,
        )

        inputs.append(mayhem_cli_exe)

        wrapper = ctx.actions.declare_file(ctx.label.name + ".bat")
        wrapper_content = """
        @echo off
        setlocal
        (echo|set /p={owner}) > {output_file}
        {mayhem_cli} {args} >> {output_file}
        """.format(
            owner=ctx.attr.owner + "/" if ctx.attr.owner else "",
            mayhem_cli=mayhem_cli_exe.path.replace("/", "\\"),
            args=" ".join(['"{}"'.format(arg) for arg in args_list]),
            output_file=mayhem_out.path.replace("/", "\\"),
        )
    else:
        mayhem_cli_exe = None
        wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")
        wrapper_content = """
        #!/bin/bash
        echo -n {owner} > {output_file}
        {mayhem_cli} --verbosity debug {args} >> {output_file}
        """.format(
            owner=ctx.attr.owner + "/" if ctx.attr.owner else "",
            mayhem_cli=ctx.executable._mayhem_cli.path,
            args=" ".join(['{}'.format(arg) for arg in args_list]),
            output_file=mayhem_out.path,
        )

    # Login first
    mayhem_login_out = mayhem_login(ctx, ctx.executable._mayhem_cli, mayhem_cli_exe, is_windows)
    inputs.append(mayhem_login_out)

    # Ideally, ctx.actions.run() would support capturing stdout/stderr
    # as described in https://github.com/bazelbuild/bazel/issues/5511
    # Or, the mayhem cli itself could support an output flag
    # An even better option would be to mark the mayhemfile rule as executable
    # This way, it would generate a mayhemfile with "mayhem init"
    # and run it with "mayhem run"
    # However, bazel treats the outputfile as the executable and attempts to run it
    # but we can't just run the Mayhemfile, we need to run "mayhem run -f Mayhemfile [opts]"
    # There is an option --run-under=<command_prefix>, but this requires a hardcoded
    # and external command, and doesn't rely on our toolchain.

    ctx.actions.write(
        output=wrapper,
        content=wrapper_content
    )

    inputs.append(wrapper)

    ctx.actions.run(
        inputs = inputs,
        outputs = [mayhem_out],
        executable = wrapper,
        progress_message = "Starting Mayhem run...",
        use_default_shell_env = True,
    )

    return_files = [mayhem_out]

    if ctx.attr.wait:
        if not ctx.attr.duration:
            fail("The 'wait' attribute requires the 'duration' attribute to be set (otherwise, we will wait forever)")
        else:
            mayhem_wait_out = mayhem_wait(ctx, ctx.executable._mayhem_cli, mayhem_cli_exe, mayhem_out, is_windows, ctx.attr.junit, ctx.attr.sarif, ctx.attr.fail_on_defects)
            return_files.append(mayhem_wait_out)    

    return [
        DefaultInfo(
            files = depset(return_files),
        ),
    ]


mayhem_run = rule(
    implementation = _mayhem_run_impl,
    attrs = {
        "mayhemfile": attr.label(mandatory = False, allow_single_file = True),
        "project": attr.string(mandatory = False),
        "owner": attr.string(mandatory = False),
        "target": attr.string(mandatory = False),
        "regression": attr.bool(mandatory = False),
        "static": attr.bool(mandatory = False),
        "dynamic": attr.bool(mandatory = False),
        "coverage": attr.bool(mandatory = False),
        "image": attr.string(mandatory = False),
        "all": attr.bool(mandatory = False),
        "duration": attr.string(mandatory = False),
        "warning_as_error": attr.bool(mandatory = False),
        "ci_url": attr.string(mandatory = False),
        "merge_base_branch_name": attr.string(mandatory = False),
        "branch_name": attr.string(mandatory = False),
        "revision": attr.string(mandatory = False),
        "parent_revision": attr.string(mandatory = False),
        "scm_remote": attr.string(mandatory = False),
        "uid": attr.string(mandatory = False),
        "gid": attr.string(mandatory = False),
        "advanced_triage": attr.string(mandatory = False),
        "cmd": attr.string(mandatory = False),
        "cwd": attr.string(mandatory = False),
        "env": attr.string_dict(mandatory = False),
        "filepath": attr.string(mandatory = False),
        "network_url": attr.string(mandatory = False),
        "network_timeout": attr.string(mandatory = False),
        "network_client": attr.string(mandatory = False),
        "libfuzzer": attr.string(mandatory = False),
        "honggfuzz": attr.string(mandatory = False),
        "sanitizer": attr.string(mandatory = False),
        "max_length": attr.string(mandatory = False),
        "memory_limit": attr.string(mandatory = False),
        "insecure": attr.bool(mandatory = False),
        "target_path": attr.label(mandatory = False, allow_single_file = True),
        "testsuite": attr.string(mandatory = False),
        "wait": attr.bool(mandatory = False),
        # The following options have no effect if "wait" is False
        "junit": attr.string(mandatory = False),
        "sarif": attr.string(mandatory = False),
        "fail_on_defects": attr.bool(mandatory = False),
        "_mayhem_cli": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("@rules_mayhem//mayhem:mayhem_cli"),
            allow_single_file = True,
        ),
        '_windows_constraint': attr.label(default = '@platforms//os:windows'),
    },
)

def _mayhem_package_impl(ctx):
    target = ctx.file.binary
    package_out = ctx.actions.declare_directory(target.basename + "-pkg")

    args = ctx.actions.args()
    args.add("package")
    args.add("-o", package_out.path)
    args.add(target.path)

    ctx.actions.run(
        inputs = [target],
        outputs = [package_out],
        executable = ctx.executable._mayhem_cli,
        progress_message = "Packaging target %s to '%s'..." % (target.short_path, package_out.path),
        arguments = [args],
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(
            files = depset([package_out]),
        ),
    ]

mayhem_package = rule(
    implementation = _mayhem_package_impl,
    attrs = {
        "binary": attr.label(mandatory = True, allow_single_file = True),
        "_mayhem_cli": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("@rules_mayhem//mayhem:mayhem_cli"),
            allow_single_file = True,
        ),
    },
)

def _mayhem_download_impl(ctx):
    if ctx.attr.output_dir:
        output_dir = ctx.actions.declare_directory(ctx.attr.output_dir)
    else:
        output_dir = ctx.actions.declare_directory(ctx.attr.target + "-pkg")
    mayhem_cli = ctx.executable._mayhem_cli
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    mayhem_login(ctx, ctx.executable._mayhem_cli, is_windows)


    args = ctx.actions.args()
    args.add("download")
    args.add("-o", output_dir.path)

    if ctx.attr.owner:
        args.add(ctx.attr.owner + "/" + ctx.attr.project + "/" + ctx.attr.target)
    else:
        args.add(ctx.attr.project + "/" + ctx.attr.target)

    ctx.actions.run(
        outputs = [output_dir],
        executable = mayhem_cli,
        progress_message = "Downloading Mayhem artifacts for %s..." % ctx.label.name,
        arguments = [args],
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(
            files = depset([output_dir]),
        ),
    ]
    


mayhem_download = rule(
    implementation = _mayhem_download_impl,
    attrs = {
        "output_dir": attr.string(mandatory = False),
        "owner": attr.string(mandatory = False),
        "project": attr.string(mandatory = True),
        "target": attr.string(mandatory = True),
        "_mayhem_cli": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("@rules_mayhem//mayhem:mayhem_cli"),
            allow_single_file = True,
        ),
        '_windows_constraint': attr.label(default = '@platforms//os:windows'),
    },
)