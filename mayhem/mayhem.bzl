def _mayhemfile_impl(ctx):
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

mayhemfile = rule(
    implementation = _mayhemfile_impl,
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

def mayhem_login(ctx, mayhem_cli, is_windows):
    """ Logs into Mayhem 
    
    Args:
        ctx: The context
        mayhem_cli: The path to the Mayhem CLI
        is_windows: A boolean indicating if the OS is Windows
    """
    if is_windows:
        output_file = ctx.actions.declare_file("~\\.config\\mayhem\\mayhem")
    else: 
        output_file = ctx.actions.declare_file("~/.config/mayhem/mayhem")

    args = ctx.actions.args()
    args.add("login")
    
    if "MAYHEM_URL" in ctx.configuration.default_shell_env:
        mayhem_url = ctx.configuration.default_shell_env["MAYHEM_URL"]
        args.add(mayhem_url)
    else:
        fail("MAYHEM_URL must be set with --action_env=MAYHEM_URL=<url>")

    if "MAYHEM_TOKEN" in ctx.configuration.default_shell_env:
        mayhem_token = ctx.configuration.default_shell_env["MAYHEM_TOKEN"]
        args.add(mayhem_token)
    else:
        fail("MAYHEM_TOKEN must be set with --action_env=MAYHEM_TOKEN=<token>")

    ctx.actions.run(
        inputs = [mayhem_cli],
        outputs = [output_file],
        executable = mayhem_cli,
        arguments = [args],
        progress_message = "Logging into Mayhem...",
        use_default_shell_env = True,
    )

    return

def _mayhem_run_impl(ctx):
    target_path = ctx.file.target_path
    mayhem_out = ctx.actions.declare_file(ctx.label.name + ".out")
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    mayhem_login(ctx, ctx.executable._mayhem_cli, is_windows)

    args_list = []
    args_list.append("run")
    args_list.append(target_path.path)
    args_list.append("-f")

    if ctx.file.mayhemfile:
        inputs = [ctx.file.mayhemfile, target_path]
        args_list.append(ctx.file.mayhemfile.path)
    else:
        inputs = [target_path]
        args_list.append(target_path.path + "/Mayhemfile")

    if ctx.attr.image:
        args_list.append("--image")
        args_list.append(ctx.attr.image)

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
        set MAYHEM_CLI="{mayhem_cli}"
        set ARGS="{args}"
        set OUTPUT_FILE="{output_file}"
        %MAYHEM_CLI% %ARGS% > %OUTPUT_FILE%
        """.format(
            mayhem_cli=mayhem_cli_exe.path.replace("/", "\\"),
            args=" ".join(['\'{}\''.format(arg.replace("/", "\\")) for arg in args_list]),
            output_file=mayhem_out.path.replace("/", "\\"),
        )
    else:
        wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")
        wrapper_content = """
        #!/bin/bash
        MAYHEM_CLI="{mayhem_cli}"
        ARGS="{args}"
        OUTPUT_FILE="{output_file}"
        $MAYHEM_CLI $ARGS > $OUTPUT_FILE
        """.format(
            mayhem_cli=ctx.executable._mayhem_cli.path,
            args=" ".join(['\'{}\''.format(arg) for arg in args_list]),
            output_file=mayhem_out.path,
        )

    # Ideally, ctx.actions.run() would support capturing stdout/stderr
    # as described in https://github.com/bazelbuild/bazel/issues/5511
    # Or, the mayhem cli itself could support an ouptut flag
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
        progress_message = "Starting Mayhem run from '%s'" % (target_path.path),
        use_default_shell_env = True,
    )
    
    return [
        DefaultInfo(
            files = depset([mayhem_out]),
        ),
    ]


mayhem_run = rule(
    implementation = _mayhem_run_impl,
    attrs = {
        "mayhemfile": attr.label(mandatory = False, allow_single_file = True),
        "image": attr.string(mandatory = False),
        "target_path": attr.label(mandatory = True, allow_single_file = True, default = "."),
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