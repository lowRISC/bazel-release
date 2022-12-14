#!/usr/bin/env bash

set -euo pipefail

function usage() {
    echo "bazel run @@LABEL@@ -- [options] [release_tag]"
    echo "    -R|--repo <[HOST/]OWNER/REPO> : Select another repository"
    echo "    -d|--draft                    : Save the release as a draft instead of publishing it"
    echo "    --dry-run                     : Print the GitHub CLI invocation"
    echo "    -p|--prerelease               : Mark the release as a prerelease"
    echo "    -t|--title <string>           : Release title"
    echo "    -n|--notes <string>           : Release notes"
    echo "    -F|--notes-file <file>        : Read release notes from file"
    echo "    --target <branch>             : Target branch or git commit SHA"
    echo "    -h|-?|--help                  : This message"
    echo
    echo "If a release_tag is not given, the last git tag is assumed to be the"
    echo "desired release_tag."
}

function run() {
    if [[ ${DRY_RUN} == 0 ]]; then
        "$@"
    else
        echo "$@"
    fi
}

ARTIFACTS=(@@ARTIFACTS@@)
FILES=(@@FILES@@)
GH=@@GH@@
: "${REMOTE:=origin}"

# Environment vars substituted in from the `release` rule.
@@ENV@@

BRANCH=$(cd "$BUILD_WORKSPACE_DIRECTORY" && git branch --show-current)
RELEASE_TAG=""
REPO=()
DRAFT=()
PRERELEASE=()
TITLE=()
NOTES=()
GENERATE_NOTES=("--generate-notes")
DRY_RUN=0

# Parse the same set of arguments as `gh release create`.
while [[ $# -gt 0 ]];
do
    case "$1" in
        -R|--repo)
            REPO=("--repo" "$2")
            shift 2
            ;;
        -d|--draft)
            DRAFT=("--draft")
            shift
            ;;
        --dry-run|--dry_run)
            DRY_RUN=1
            shift
            ;;
        -p|--prerelease)
            PRERELEASE=("--prerelease")
            shift
            ;;
        -t|--title)
            TITLE=("--title" "$2")
            shift 2
            ;;
        -n|--notes)
            NOTES=("--notes" "$2")
            GENERATE_NOTES=()
            shift 2
            ;;
        -F|--notes-file)
            NOTES=("--notes-file" "$2")
            GENERATE_NOTES=()
            shift 2
            ;;
        --target)
            BRANCH="$2"
            shift 2
            ;;
        -\?|-h|--help)
            usage
            exit
            ;;
        -*)
            echo "Unknown argument: ${1}"
            usage
            exit 1
            ;;
        *)
            RELEASE_TAG="$1"
            shift
            ;;
    esac
done

if [[ -z "${RELEASE_TAG}" ]]; then
    RELEASE_TAG=$(cd "$BUILD_WORKSPACE_DIRECTORY" && git describe --abbrev=0 --tags)
fi

if $(${GH} release list | egrep -q "\s${RELEASE_TAG}\s"); then
    echo "A release with tag ${RELEASE_TAG} already exists."
    echo
    echo "To make a new release, create a new tag first or specify the tag on"
    echo "the command line."
    usage
    exit 1
fi

declare -A DIGEST=()
for f in "${FILES[@]}"; do
    b=$(basename ${f})
    DIGEST[${b}]=$(sha256sum ${f} | cut -f1 -d' ')
done

export ARTIFACTS BRANCH FILES GH REMOTE RELEASE_TAG DIGEST

# A script fragment substituted in from the `release` rule.
@@SCRIPT@@
# End script.

run ${GH} release "${REPO[@]}" create \
    --target="${BRANCH}" "${RELEASE_TAG}" \
    "${DRAFT[@]}" \
    "${PRERELEASE[@]}" \
    "${TITLE[@]}" \
    "${GENERATE_NOTES[@]}" \
    "${NOTES[@]}" \
    "${ARTIFACTS[@]}"
