# bazel-release
Bazel automated GitHub release process

This repository contains bazel automation for performing releases to GitHub.

## Usage

Load this repository in your `WORKSPACE`:

```
http_archive(
    name = "lowrisc_bazel_release",
    url = "<TODO>",
    sha256 = "<TODO>",
    strip_prefix = "<TODO>",
)


load("@lowrisc_bazel_release//:repos.bzl", "lowrisc_bazel_release_repos")
lowrisc_bazel_release_repos()
load("//:deps.bzl", "lowrisc_bazel_release_deps")
lowrisc_bazel_release_deps()
```

Then, in a `BUILD` file, instantiate the `release` rule:

```
load("@lowrisc_bazel_release//release:release.bzl", "release")

release(
    name = "release",
    artifacts = {
        "//:your_release_artifact": "Binary release of my project",
    },
)
```

When you want to perform a release, run the `release` target:

```
bazel run :release -- <your release tag name>
```

Bazel will build your release artifacts, and then use the GitHub CLI to
create a release on GitHub and upload your release artifacts.
