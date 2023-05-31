def mayhem(**kwargs):
    _mayhem(
        source_file = "{name}.mayhemfile".format(**kwargs),
        **kwargs
    )

def _mayhem_impl(ctx):
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

    if ctx.attr.run:
      mayhemfile = ctx.outputs.source_file
      mayhem_out = ctx.actions.declare_file(mayhemfile.basename + ".out")

      ctx.actions.run_shell(
          inputs = [mayhemfile],
          outputs = [mayhem_out],
          progress_message = "Starting Mayhem run from %s..." % mayhemfile.short_path,
          command = "mayhem run . -f '%s' > '%s'" % (mayhemfile.path, mayhem_out.path),
      )
      return [
          DefaultInfo(
              files = depset([mayhem_out]),
          ),
      ]

_mayhem = rule(
    implementation = _mayhem_impl,
    attrs = {
        "run": attr.bool(mandatory = True),
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
