# def _mayhem_toolchain_impl(ctx):
#     toolchain_info = platform_common.ToolchainInfo(
#         mayhem_cli = ctx.attr.mayhem_cli
#     )
#     return [toolchain_info]

# mayhem_toolchain = rule(
#     implementation = _mayhem_toolchain_impl,
#     attrs = {
#         "mayhem_cli": attr.label(
#             default = Label("//mayhem:mayhem_cli"),
#             executable = True,
#             cfg = "exec",
#         ),
#     },
# )