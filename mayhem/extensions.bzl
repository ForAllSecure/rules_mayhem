load("@rules_mayhem//mayhem:repositories.bzl", "rules_mayhem_repositories")

def _rules_mayhem_extension_impl(_ctx):
    mayhem_url = _ctx.getenv("MAYHEM_URL")
    rules_mayhem_repositories(mayhem_url)

rules_mayhem_extension = module_extension(
    implementation = _rules_mayhem_extension_impl,
)
