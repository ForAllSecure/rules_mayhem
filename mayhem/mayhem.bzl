def mayhem_file(**kwargs):
    _mayhem_file(
        source_file = "{name}.mayhemfile".format(**kwargs),
        **kwargs
    )

def _mayhem_file_impl(ctx):
    ctx.actions.expand_template(
        template = ctx.file._template,
        output = ctx.outputs.source_file,
        substitutions = {
            "{VERSION}": "version: '{}'".format(ctx.attr.version) if ctx.attr.version else "",
            "{PROJECT}": ctx.attr.project,
            "{TARGET}": ctx.attr.target,
            "{IMAGE}": ctx.attr.image,
            "{COMMAND}": ctx.attr.command,
            "{DURATION}": "duration: {}".format(ctx.attr.duration) if ctx.attr.duration else "",
            "{ADV_TRIAGE}": "advanced_triage: true" if ctx.attr.advanced_triage == "true" else "advanced_triage: false",
            "{TASKS}": "tasks: \n  - name: {}".format("\n  - name: ".join(ctx.attr.tasks)) if ctx.attr.tasks else "",
            "{TESTSUITE}": "testsuite: \n  - {}".format("\n'  - ".join(ctx.attr.testsuite)) if ctx.attr.testsuite else "",
            "{UID}": "uid: {}".format(ctx.attr.uid) if ctx.attr.uid else "",
            "{GID}": "gid: {}".format(ctx.attr.gid) if ctx.attr.gid else "",
            "{SECOND_COMMAND}": "- cmd: {}".format(ctx.attr.second_command) if ctx.attr.second_command else "",
            "{ENV}": "{}".format(ctx.attr.env) if ctx.attr.env else "{}",
            "{LIBFUZZER}": "libfuzzer: {}".format(ctx.attr.libfuzzer) if ctx.attr.libfuzzer else "",
            "{AFL}": "afl: {}".format(ctx.attr.afl) if ctx.attr.afl else "",
            "{HONGGFUZZ}": "honggfuzz: {}".format(ctx.attr.honggfuzz) if ctx.attr.honggfuzz else "",
            "{SANITIZER}": "sanitizer: {}".format(ctx.attr.sanitizer) if ctx.attr.sanitizer else "",
            "{CWD}": "cwd: {}".format(ctx.attr.cwd) if ctx.attr.cwd else "",
            "{FILEPATH}": "filepath: {}".format(ctx.attr.filepath) if ctx.attr.filepath else "",
            "{NETWORK}" : "network: \n      {}".format("\n      ".join(ctx.attr.network)) if ctx.attr.network else "",
            "{MAX_LENGTH}": "max_length: {}".format(ctx.attr.max_length) if ctx.attr.max_length else "",
            "{CMD_TIMEOUT}": "timeout: {}".format(ctx.attr.cmd_timeout) if ctx.attr.cmd_timeout else "",
            "{MEMORY_LIMIT}": "memory_limit: {}".format(ctx.attr.memory_limit) if ctx.attr.memory_limit else "",
            "{DICTIONARY}": "dictionary: {}".format(ctx.attr.dictionary) if ctx.attr.dictionary else "",

        },
    )

def _mayhem_run_impl(ctx):
  # The input file is given to us from the BUILD file via an attribute.
    in_file = ctx.file.mayhemfile

    # The output file is declared with a name based on the target's name.
    out_file = ctx.actions.declare_file("%s.mayhem" % ctx.attr.name)

    ctx.actions.run_shell(
        inputs = [in_file],
        outputs = [out_file],
        progress_message = "Starting Mayhem run defined in %s..." % in_file.short_path,
        # The command to run. Alternatively we could use '$1', '$2', etc., and
        # pass the values for their expansion to `run_shell`'s `arguments`
        # param (see convert_to_uppercase below). This would be more robust
        # against escaping issues. Note that actions require the full `path`,
        # not the ambiguous truncated `short_path`.
        command = "mayhem run . -f '%s' > '%s'" % (in_file.path, out_file.path),
    )

    # Tell Bazel that the files to build for this target includes
    # `out_file`.
    return [DefaultInfo(files = depset([out_file]))]


_mayhem_file = rule(
    implementation = _mayhem_file_impl,
    attrs = {
        "version": attr.string(mandatory = False),
        "project": attr.string(mandatory = True),
        "target": attr.string(mandatory = True),
        "image": attr.string(mandatory = True),
        "command": attr.string(mandatory = True),
        "duration": attr.string(mandatory = False),
        "advanced_triage": attr.string(mandatory = False),
        "tasks": attr.string_list(mandatory = False),
        "testsuite": attr.string_list(mandatory = False),
        "uid": attr.string(mandatory = False),
        "gid": attr.string(mandatory = False),
        "second_command": attr.string(mandatory = False),
        "env": attr.string_dict(mandatory = False),
        "libfuzzer": attr.string(mandatory = False),
        "afl": attr.string(mandatory = False),
        "honggfuzz": attr.string(mandatory = False),
        "sanitizer": attr.string(mandatory = False),
        "cwd": attr.string(mandatory = False),
        "filepath": attr.string(mandatory = False),
        "network": attr.string_list(mandatory = False),
        "max_length": attr.string(mandatory = False),
        "cmd_timeout": attr.string(mandatory = False),
        "memory_limit": attr.string(mandatory = False),
        "dictionary": attr.string(mandatory = False),
        "_template": attr.label(
            default = ":mayhemfile.template",
            allow_single_file = True,
        ),
        "source_file": attr.output(mandatory = True),
    },
)

mayhem_run = rule(
    implementation = _mayhem_run_impl,
    attrs = {
        "mayhemfile": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The Mayhemfile for the target",
        ),
    },
    doc = "Runs a Mayhemfile generated by mayhem_file()",
)
