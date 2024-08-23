def _mayhemfile_impl(ctx):
    mayhemfile = ctx.actions.declare_file(ctx.label.name + ".mayhemfile")

    if ctx.attr.owner:
        full_project = ctx.attr.owner + "/" + ctx.attr.project
    else:
        full_project = ctx.attr.project

    command = [
        "'%s' init -o '%s'" % (ctx.executable._mayhem_bin.path, mayhemfile.path),
        "--project '%s'" % full_project,
        "--target '%s'" % ctx.attr.target,
        "--cmd '%s'" % ctx.attr.cmd,
    ]

    if ctx.attr.image:
        command.append("--image '%s'" % ctx.attr.image)
    if ctx.attr.duration:
        command.append("--duration '%s'" % ctx.attr.duration)
    if ctx.attr.uid:
        command.append("--uid '%s'" % ctx.attr.uid)
    if ctx.attr.gid:
        command.append("--gid '%s'" % ctx.attr.gid)
    if ctx.attr.advanced_triage:
        command.append("--advanced-triage '%s'" % ctx.attr.advanced_triage)
    if ctx.attr.cwd:
        command.append("--cwd '%s'" % ctx.attr.cwd)
    if ctx.attr.filepath:
        command.append("--filepath '%s'" % ctx.attr.filepath)
    if ctx.attr.env:
        for key, value in ctx.attr.env.items():
            command.append("--env '%s=%s'" % (key, value))
    if ctx.attr.network_url:
        command.append("--network-url '%s'" % ctx.attr.network_url)
    if ctx.attr.network_timeout:
        command.append("--network-timeout '%s'" % ctx.attr.network_timeout)
    if ctx.attr.network_client == "true":
        command.append("--network-client")
    if ctx.attr.libfuzzer == "true":
        command.append("--libfuzzer")
    if ctx.attr.honggfuzz == "true":
        command.append("--honggfuzz")
    if ctx.attr.sanitizer == "true":
        command.append("--sanitizer")
    if ctx.attr.max_length:
        command.append("--max-length '%s'" % ctx.attr.max_length)
    if ctx.attr.memory_limit:
        command.append("--memory-limit '%s'" % ctx.attr.memory_limit)

    # Join the command parts into a single string
    command_str = " ".join(command)

    ctx.actions.run_shell(
        inputs = [ctx.executable._mayhem_bin],
        outputs = [mayhemfile],
        progress_message = "Generating Mayhemfile for %s..." % ctx.label.name,
        command = command_str,
        execution_requirements = {"local": "true"},
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
        "_mayhem_bin": attr.label(executable = True, cfg = "exec", default = Label("//:mayhem")),
    },
)

def _mayhem_run_impl(ctx):
    target_path = ctx.file.target_path
    mayhem_out = ctx.actions.declare_file(ctx.label.name + ".out")

    command = [
        ctx.executable._mayhem_bin.path,
        "run",
        target_path.path,
        "-f",
    ]

    if ctx.file.mayhemfile:
        command.append(ctx.file.mayhemfile.path)
    else:
        command.append(target_path.path + "/Mayhemfile")

    if ctx.attr.image:
        command.extend(["--image", ctx.attr.image])

    command_str = " ".join(command) + " > " + mayhem_out.path

    ctx.actions.run_shell(
        inputs = [target_path, ctx.executable._mayhem_bin],
        outputs = [mayhem_out],
        progress_message = "Starting Mayhem run from '%s'" % (target_path.path),
        command = command_str,
        execution_requirements = {"local": "true"},
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
        "_mayhem_bin": attr.label(executable = True, cfg = "exec", default = Label("//:mayhem")),
    },
)

def _mayhem_package_impl(ctx):
    target = ctx.file.binary
    package_out = ctx.actions.declare_directory(target.basename + "-pkg")

    ctx.actions.run_shell(
        inputs = [target, ctx.executable._mayhem_bin],
        outputs = [package_out],
        progress_message = "Packaging target %s to '%s'..." % (target.short_path, package_out.path),
        command = "'%s' package -o '%s' '%s'" % (ctx.executable._mayhem_bin.path, package_out.path, target.path),
        execution_requirements = {"local": "true"},
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
        "_mayhem_bin": attr.label(executable = True, cfg = "exec", default = Label("//:mayhem")),
    },
)




