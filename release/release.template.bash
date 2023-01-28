#!/usr/bin/env bash

set -euo pipefail

function usage() {
    echo "bazel run @@LABEL@@ -- [options] [release_tag]"
    echo "    -R|--repo <[HOST/]OWNER/REPO> : Select another repository"
    echo "    -d|--draft                    : Save the release as a draft instead of publishing it"
    echo "    --[no]dry-run                 : Print the GitHub CLI invocation"
    echo "    -p|--prerelease               : Mark the release as a prerelease"
    echo "    -t|--title <string>           : Release title"
    echo "    -n|--notes <string>           : Release notes"
    echo "    -F|--notes-file <file>        : Read release notes from file"
    echo "    --target <branch>             : Target branch or git commit SHA"
    echo "    --[no]script                  : Run (or skip) the 'script' portion of process"
    echo "    --[no]release                 : Perform (or skip) the relese process on github"
    echo "    --copy <subdir>               : Copy the release artifacts to the named subdir"
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

function option_or_no() {
  if [[ "$1" == "--no"* ]]; then
    echo 0
  else
    echo 1
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
SCRIPT=1
RELEASE=1
COPY=""

# Parse the same set of arguments as `gh release create`.
shopt -s extglob
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
        --?(no)dry[-_]run)
            DRY_RUN=1
            DRY_RUN=$(option_or_no "$1")
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
        --copy)
            COPY="$2"
            shift 2
            ;;
        --?(no)release)
            RELEASE=$(option_or_no "$1")
            shift
            ;;
        --?(no)script)
            SCRIPT=$(option_or_no "$1")
            shift
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

if [[ ${RELEASE} == 1 ]] && $(${GH} release list | egrep -q "\s${RELEASE_TAG}\s"); then
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

if [[ ${SCRIPT} == 1 ]]; then
    # Do something in case the substitution is empty.
    true
    # A script fragment substituted in from the `release` rule.
    @@SCRIPT@@
    # End script.
fi

if [[ ! -z "${COPY}" ]]; then
    run mkdir -p "${COPY}"
    # We use `--no-preserve=mode` because bazel creates files
    # with mode 0444.
    run cp --no-preserve=mode -t "${COPY}" "${FILES[@]}"
fi

if [[ ${RELEASE} == 1 ]]; then
    run ${GH} release "${REPO[@]}" create \
        --target="${BRANCH}" "${RELEASE_TAG}" \
        "${DRAFT[@]}" \
        "${PRERELEASE[@]}" \
        "${TITLE[@]}" \
        "${GENERATE_NOTES[@]}" \
        "${NOTES[@]}" \
        "${ARTIFACTS[@]}"
fi
