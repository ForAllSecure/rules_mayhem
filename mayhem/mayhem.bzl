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

def _mayhem_run_impl(ctx):
    runfiles = ctx.runfiles(files=[ctx.executable._mayhem_cli])
    runfiles = runfiles.merge(ctx.attr._mayhem_cli[DefaultInfo].default_runfiles)
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    run_args = []
    if ctx.attr.verbosity:
        if ctx.attr.verbosity not in ["debug", "info"]:
            fail("Invalid verbosity level: {}. Valid values are 'debug' or 'info'.".format(ctx.attr.verbosity))
        else:
            run_args.append("--verbosity")
            run_args.append(ctx.attr.verbosity)
    run_args.append("run")

    if ctx.file.mayhemfile:
        mayhemfile_path = ctx.file.mayhemfile.short_path
        run_args.append(".")
        run_args.append("-f")
        run_args.append(mayhemfile_path)
        runfiles = runfiles.merge(ctx.runfiles(files=[ctx.file.mayhemfile]))
    elif ctx.file.target_path:
        mayhemfile_path = ctx.file.target_path.short_path + "/Mayhemfile"
        run_args.append(ctx.file.target_path.short_path)
        run_args.append("-f")
        run_args.append(mayhemfile_path)
        runfiles = runfiles.merge(ctx.runfiles(files=[ctx.file.target_path]))
    elif ctx.attr.image:
        run_args.append(ctx.attr.image)
        run_args.append("--docker")
        if ctx.attr.image_dependency:
            runfiles = runfiles.merge(ctx.attr.image_dependency[DefaultInfo].default_runfiles)
    else:
        fail("Either mayhemfile, image or target_path must be set")

    if ctx.attr.regression:
        run_args.append("--regression")
    if ctx.attr.static:
        run_args.append("--static")
    if ctx.attr.dynamic:
        run_args.append("--dynamic")
    if ctx.attr.coverage:
        run_args.append("--coverage")
    if ctx.attr.all:
        run_args.append("--all")
    if ctx.attr.owner:
        run_args.append("--owner")
        run_args.append(ctx.attr.owner)
    if ctx.attr.project:
        run_args.append("--project")
        run_args.append(ctx.attr.project)
    if ctx.attr.target:
        run_args.append("--target")
        run_args.append(ctx.attr.target)
    if ctx.attr.cmd:
        run_args.append("--cmd")
        run_args.append("'{}'".format(ctx.attr.cmd))
    if ctx.attr.image:
        run_args.append("--image")
        run_args.append(ctx.attr.image)
    if ctx.attr.duration:
        run_args.append("--duration")
        run_args.append(ctx.attr.duration)
    if ctx.attr.warning_as_error:
        run_args.append("--warning-as-error")
    if ctx.attr.ci_url:
        run_args.append("--ci-url")
        run_args.append(ctx.attr.ci_url)
    if ctx.attr.merge_base_branch_name:
        run_args.append("--merge-base-branch-name")
        run_args.append(ctx.attr.merge_base_branch_name)
    if ctx.attr.branch_name:
        run_args.append("--branch-name")
        run_args.append(ctx.attr.branch_name)
    if ctx.attr.revision:
        run_args.append("--revision")
        run_args.append(ctx.attr.revision)
    if ctx.attr.parent_revision:
        run_args.append("--parent-revision")
        run_args.append(ctx.attr.parent_revision)
    if ctx.attr.scm_remote:
        run_args.append("--scm-remote")
        run_args.append(ctx.attr.scm_remote)
    if ctx.attr.uid:
        run_args.append("--uid")
        run_args.append(ctx.attr.uid)
    if ctx.attr.gid:
        run_args.append("--gid")
        run_args.append(ctx.attr.gid)
    if ctx.attr.advanced_triage:
        run_args.append("--advanced-triage")
        run_args.append(ctx.attr.advanced_triage)
    if ctx.attr.cwd:
        run_args.append("--cwd")
        run_args.append(ctx.attr.cwd)
    if ctx.attr.filepath:
        run_args.append("--filepath")
        run_args.append(ctx.attr.filepath)
    if ctx.attr.env:
        for key, value in ctx.attr.env.items():
            run_args.append("--env")
            run_args.append(key + "=" + value)
    if ctx.attr.network_url:
        run_args.append("--network-url")
        run_args.append(ctx.attr.network_url)
    if ctx.attr.network_timeout:
        run_args.append("--network-timeout")
        run_args.append(ctx.attr.network_timeout)
    if ctx.attr.network_client == "true":
        run_args.append("--network-client")
        run_args.append(ctx.attr.network_client)
    if ctx.attr.libfuzzer == "true":
        run_args.append("--libfuzzer")
        run_args.append(ctx.attr.libfuzzer)
    if ctx.attr.honggfuzz == "true":
        run_args.append("--honggfuzz")
        run_args.append(ctx.attr.honggfuzz)
    if ctx.attr.sanitizer == "true":
        run_args.append("--sanitizer")
        run_args.append(ctx.attr.sanitizer)
    if ctx.attr.max_length:
        run_args.append("--max-length")
        run_args.append(ctx.attr.max_length)
    if ctx.attr.memory_limit:
        run_args.append("--memory-limit")
        run_args.append(ctx.attr.memory_limit)
    if ctx.attr.testsuite:
        run_args.append("--testsuite")
        run_args.append(ctx.attr.testsuite)

    # For self-signed instances
    if ctx.attr.insecure:
        run_args.append("--insecure")

    run_args_str = " ".join(['"{}"'.format(arg) for arg in run_args])
    wait_args_str = ""

    # For mayhem wait
    if ctx.attr.wait:
        if not ctx.attr.duration:
            fail("The 'wait' attribute requires the 'duration' attribute to be set (otherwise, we will wait forever)")
        wait_args = []
        wait_args.append("wait")
        if ctx.attr.owner:
            wait_args.append("--owner")
            wait_args.append(ctx.attr.owner)
        if ctx.attr.junit:
            wait_args.append("--junit")
            wait_args.append(ctx.attr.junit)
        if ctx.attr.sarif:
            wait_args.append("--sarif")
            wait_args.append(ctx.attr.sarif)
        if ctx.attr.fail_on_defects:
            wait_args.append("--fail-on-defects")

        wait_args_str = " ".join(['"{}"'.format(arg) for arg in wait_args])

    if is_windows:
         # Need to copy the Mayhem CLI to have .exe extension
        mayhem_cli_exe = ctx.actions.declare_file(ctx.executable._mayhem_cli.short_path + ".exe")

        ctx.actions.symlink(
            output = mayhem_cli_exe,
            target_file = ctx.executable._mayhem_cli,
            is_executable = True,
        )

        runfiles = runfiles.merge(ctx.runfiles(files=[mayhem_cli_exe]))

        wrapper = ctx.actions.declare_file(ctx.label.name + ".bat")
        
        if wait_args_str:
            wrapper_content = """
            @echo off
            setlocal
            for /f "tokens=*" %%i in ('{mayhem_cli} {run_args}') do (
                {mayhem_cli} {wait_args} "%%i"
                {mayhem_cli} show "%%i"
            )
            """.format(
                mayhem_cli=mayhem_cli_exe.short_path.replace("/", "\\"),
                run_args=run_args_str,
                wait_args=wait_args_str,
            )    
        else:
            wrapper_content = """
            @echo off
            setlocal
            {mayhem_cli} {run_args}
            """.format(
                mayhem_cli=mayhem_cli_exe.short_path.replace("/", "\\"),
                run_args=run_args_str,
            )
    else:
        mayhem_cli_exe = None
        wrapper = ctx.actions.declare_file(ctx.label.name + ".sh")
        if wait_args_str:
            wrapper_content = """
            #!/bin/bash
            run_id=$({mayhem_cli} {run_args})
            {mayhem_cli} {wait_args} $run_id
            {mayhem_cli} show $run_id
            """.format(
                mayhem_cli=ctx.executable._mayhem_cli.short_path,
                run_args=run_args_str,
                wait_args=wait_args_str,
            )
        else:
            wrapper_content = """
            #!/bin/bash
            {mayhem_cli} {run_args}
            """.format(
                mayhem_cli=ctx.executable._mayhem_cli.short_path,
                run_args=run_args_str,
            )

    ctx.actions.write(
        output=wrapper,
        content=wrapper_content,
        is_executable=True
    )

    return [
        DefaultInfo(
            # files = depset(return_files),
            executable = wrapper,
            runfiles = runfiles,
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
        "image_dependency": attr.label(mandatory = False, executable = True, cfg = "exec"),
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
        "verbosity": attr.string(mandatory = False),
        "_mayhem_cli": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("@rules_mayhem//mayhem:mayhem_cli"),
            allow_single_file = True,
        ),
        '_windows_constraint': attr.label(default = '@platforms//os:windows'),
    },
    executable = True,
)

def _mayhem_package_impl(ctx):
    target = ctx.file.binary
    package_out = ctx.actions.declare_directory(target.basename + "-pkg")

    args = ctx.actions.args()
    if ctx.attr.verbosity:
        if ctx.attr.verbosity not in ["debug", "info"]:
            fail("Invalid verbosity level: {}. Valid values are 'debug' or 'info'.".format(ctx.attr.verbosity))
        else:
            args.add("--verbosity", ctx.attr.verbosity)
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
        "verbosity": attr.string(mandatory = False),
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

    args = ctx.actions.args()
    if ctx.attr.verbosity:
        if ctx.attr.verbosity not in ["debug", "info"]:
            fail("Invalid verbosity level: {}. Valid values are 'debug' or 'info'.".format(ctx.attr.verbosity))
        else:
            args.add("--verbosity", ctx.attr.verbosity)
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
        "verbosity": attr.string(mandatory = False),
        "_mayhem_cli": attr.label(
            executable = True,
            cfg = "exec",
            default = Label("@rules_mayhem//mayhem:mayhem_cli"),
            allow_single_file = True,
        ),
        '_windows_constraint': attr.label(default = '@platforms//os:windows'),
    },
)