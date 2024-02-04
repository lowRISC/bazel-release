# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("//third_party/github:repos.bzl", "github_tools_repos")

tools = module_extension(
    implementation = lambda ctx: github_tools_repos(),
)
