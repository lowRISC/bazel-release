# bazel-release
Bazel automated GitHub release process

This repository contains bazel automation for performing releases to GitHub.

## Usage

### Configuration

Load this repository in your `WORKSPACE`:

```
http_archive(
    name = "lowrisc_bazel_release",
    url = "https://github.com/lowRISC/bazel-release/archive/refs/tags/v0.0.1.tar.gz",
    sha256 = "b4a6518347f4c95b218c4358e2ce946be0100ff731ccc4922cb1f8e1acc9e09d",
    strip_prefix = "bazel-release-0.0.1",
)


load("@lowrisc_bazel_release//:repos.bzl", "lowrisc_bazel_release_repos")
lowrisc_bazel_release_repos()
load("@lowrisc_bazel_release//:deps.bzl", "lowrisc_bazel_release_deps")
lowrisc_bazel_release_deps()
```

### Defining the Release

In a `BUILD` file, instantiate the `release` rule and provide the
labels and descriptions of your release artifacts:

```
load("@lowrisc_bazel_release//release:release.bzl", "release")

release(
    name = "release",
    artifacts = {
        "//:your_release_artifact": "Binary release of my project",
    },
)
```

### Releasing

#### Manual Release

When you want to perform a release, run the `release` target:

```
bazel run :release -- <your release tag name>
```

Bazel will build your release artifacts, and then use the GitHub CLI to
create a release on GitHub and upload your release artifacts.

#### Automation with Github Actions

To create a release via Github actions, execute the release rule
as a step in your workflow configuration.  See the
[`create_release.yml`](.github/workflows/create_release.yml) file in
this repository as an example.
