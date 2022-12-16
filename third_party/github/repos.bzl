# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def github_tools_repos():
    http_archive(
        name = "com_github_gh",
        url = "https://github.com/cli/cli/releases/download/v2.20.2/gh_2.20.2_linux_amd64.tar.gz",
        sha256 = "3bc7cd3b2fd9082218b8246595673f55badb351db1b9e627eec121beb8b26450",
        build_file = Label("//third_party/github:BUILD.gh.bazel"),
        strip_prefix = "gh_2.20.2_linux_amd64",
    )
