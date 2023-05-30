def _mayhem_validation_test_impl(ctx):
  """Rule for instantiating mayhem_validator.sh.template for a given target."""
  exe = ctx.outputs.executable
  target = ctx.file.target
  ctx.actions.expand_template(output = exe,
                              template = ctx.file._script,
                              is_executable = True,
                              substitutions = {
                                "%MAYHEMFILE%": target.short_path,
                              })
  # This is needed to make sure the output file of mayhem is visible to the
  # resulting instantiated script.
  return [DefaultInfo(runfiles=ctx.runfiles(files=[target]))]

mayhem_validation_test = rule(
    implementation = _mayhem_validation_test_impl,
    attrs = {"target": attr.label(allow_single_file=True),
             # You need an implicit dependency in order to access the template.
             # A target could potentially override this attribute to modify
             # the test logic.
             "_script": attr.label(allow_single_file=True,
                                   default=Label("//mayhem:mayhem_validator"))},
    test = True,
)
