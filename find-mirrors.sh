#!/usr/bin/env bash
# Requires: Bash, GNU grep and parallel, htmlq, and httpie or xh.
# Usage:
#        ./find-mirrors.sh ARCH DISTRO REPOSITORY PROTOCOL JOBS
# Example:
#        ./find-mirrors.sh armhf focal main https 6
#
# Copyright 2022 Alex DeLorenzo. Licensed under the GPLv3.
#
export ARCH="${1:-${ARCH:-amd64}}"
export DISTRO="${2:-${DISTRO:-focal}}"
export REPOSITORY="${3:-${REPOSITORY:-main}}"
export PROTOCOL="${4:-${PROTOCOL:-http}}"
export JOBS="${5:-${JOBS:-4}}"

export URL_PATH="dists/$DISTRO/$REPOSITORY/binary-$ARCH/"
export LIST_URL="https://launchpad.net/ubuntu/+archivemirrors/"
export SELECTOR="#mirrors_list > tbody > tr > td:nth-child(2) > a"
export TIMEOUT=10

export NO_PARALLEL="GNU parallel is missing, installing with apt...\n"
export NO_HTMLQ="You need to install htmlq: https://github.com/mgdm/htmlq\n"
export APT_BIN_FMT="deb %s %s %s\n"
export APT_SRC_FMT="deb-src %s %s %s\n"

export RC_MISSING_DEPS=1
export RC_BAD_MIRROR=2

set -Eeuo pipefail
shopt -s expand_aliases


alias quiet="&>/dev/null"
alias quiet-err="2>/dev/null"
alias newline="printf '\n'"
alias installHttp='python3 -m pip install --upgrade httpie'


exists() {
  quiet which $@
}


getDependencies() {
  exists parallel || {
    printf "%s" "$NO_PARALLEL"
    sudo apt install parallel
  }

  exists xh || exists http || {
    installHttp || return $RC_MISSING_DEPS
  }

  export http=http
  exists xh && export http=xh

  exists htmlq || {
    printf "%s" "$NO_HTMLQ"
    return $RC_MISSING_DEPS
  }
}


getMirrors() {
  $http --body --follow get "$LIST_URL" \
    | htmlq "$SELECTOR" --attribute href \
    | grep -i "$PROTOCOL:"
} quiet-err


checkRepo() {
  local url="$1"

  $http get "$url" \
    --quiet --quiet \
    --timeout $TIMEOUT \
    --verify=no \
    --ignore-stdin \
    --follow \
    --headers \
    --check-status
} quiet-err
export -f checkRepo


toAptSource() {
  local url="$1"
  local args=("$url" "$DISTRO" "$REPOSITORY")

  printf "$APT_BIN_FMT" "${args[@]}"
  printf "$APT_SRC_FMT" "${args[@]}"
}
export -f toAptSource


testMirror() {
  local url="$1"
  local repoUrl="$url/$URL_PATH"

  checkRepo "$repoUrl" || return $RC_BAD_MIRROR

  toAptSource "$url"
  newline
}
export -f testMirror


testMirrors() {
  parallel --will-cite --jobs "$JOBS" testMirror
}


main() {
  getDependencies || return $RC_MISSING_DEPS
  getMirrors | testMirrors
}


main
