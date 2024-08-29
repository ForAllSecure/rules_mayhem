# load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

# def rules_mayhem_repositories():
#     http_file(
#         name = "mayhem_cli_linux",
#         urls = ["https://app.mayhem.security/cli/Linux/mayhem"],
#         executable = True,
#     )
    
#     http_file(
#         name = "mayhem_cli_windows",
#         urls = ["https://app.mayhem.security/cli/Windows/mayhem.exe"],
#         executable = True,
#     )
    
#     http_file(
#         name = "yq_cli_linux",
#         urls = ["https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_amd64"],
#         sha256 = "a2c097180dd884a8d50c956ee16a9cec070f30a7947cf4ebf87d5f36213e9ed7",
#         executable = True,
#     )
    
#     http_file(
#         name = "yq_cli_windows",
#         urls = ["https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_windows_amd64.exe"],
#         sha256 = "d509d51e6db30ebb7c9363b7ca8714224f93a456a421d7a7819ab564b868acc7",
#         executable = True,
#     )