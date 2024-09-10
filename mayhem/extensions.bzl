load("@rules_mayhem//mayhem:repositories.bzl", "rules_mayhem_repositories", "rules_mayhem_archives")
def _rules_mayhem_dependencies_impl(_ctx):
    rules_mayhem_repositories()
    rules_mayhem_archives()

rules_mayhem_dependencies = module_extension(
    implementation = _rules_mayhem_dependencies_impl,
)
