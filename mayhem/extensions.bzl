load("@rules_mayhem//mayhem:repositories.bzl", "rules_mayhem_repositories")
load("//:mayhem_secrets.bzl", "mayhem_url")

def _rules_mayhem_extension_impl(_ctx):
    rules_mayhem_repositories(mayhem_url)

rules_mayhem_extension = module_extension(
    implementation = _rules_mayhem_extension_impl,
)
