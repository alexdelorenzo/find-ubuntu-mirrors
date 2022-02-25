#!/usr/bin/env bash
# Requires: Bash, GNU grep and parallel, htmlq, and httpie or xh.
# Usage: 
#        ./find-mirrors.sh ARCH DISTRO REPOSITORY PROTOCOL JOBS
# Example: 
#        ./find-mirrors.sh armhf focal main https 6
#
# Copyright 2022 Alex DeLorenzo. Licensed under the GPLv3.
#
export ARCH="${1:-amd64}"
export DISTRO="${2:-focal}"
export REPOSITORY="${3:-main}"
export PROTOCOL="${4:-http}"
export JOBS="${5:-4}"

export URL_PATH="dists/$DISTRO/$REPOSITORY/binary-$ARCH/"
export LIST_URL="https://launchpad.net/ubuntu/+archivemirrors/"
export SELECTOR="#mirrors_list > tbody > tr > td:nth-child(2) > a"
export TIMEOUT=10

export RC_MISSING_DEPS=1
export NO_PARALLEL="GNU parallel is missing, installing with apt...\n"
export NO_HTMLQ="You need to install htmlq: https://github.com/mgdm/htmlq\n"

set -u


quiet() {
  "$@" &> /dev/null
}
export -f quiet


exists() {
  quiet which $@
}


getDependencies() {
  exists parallel || {
    printf "%s" "$NO_PARALLEL"
    sudo apt install parallel
  }

  exists xh || exists http ||
    python3 -m pip install --upgrade httpie &&
    export http=http ||
      return $RC_MISSING_DEPS

  exists xh &&
    export http=xh

  exists htmlq || {
    printf "%s" "$NO_HTMLQ"
    return $RC_MISSING_DEPS
  }

  echo $http
}

getMirrors() {
  $http --body --follow get "$LIST_URL" \
    | htmlq "$SELECTOR" --attribute href \
    | grep -i "$PROTOCOL:"
}


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
}
export -f checkRepo


testMirror() {
  local url="$1"
  local repoUrl="$url/$URL_PATH"

  checkRepo "$repoUrl" &&
    printf "Valid: %s\n" "$url"
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
