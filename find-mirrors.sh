#!/usr/bin/env bash
# Copyright 2022 Alex DeLorenzo. Licensed under the GPLv3.
# Requires: Bash, GNU grep and parallel, htmlq, and httpie or xh.
export ARCH="${1:-amd64}"
export DISTRO="${2:-focal}"
export REPOSITORY="${3:-main}"
export PROTO="${4:-http}"
export JOBS="${5:-4}"

export URL_PATH="dists/$DISTRO/$REPOSITORY/binary-$ARCH/"
export LIST_URL="https://launchpad.net/ubuntu/+archivemirrors/"
export SELECTOR="#mirrors_list > tbody > tr > td:nth-child(2) > a"
export NO_PARALLEL="GNU parallel is missing, installing with apt...\n"
export MAX_TIME=10


quiet() {
  $@ &> /dev/null
}
export -f quiet


getDependencies() {
  quiet which parallel || {
    printf "$NO_PARALLEL"
    sudo apt install parallel
  }

  quiet which xh || quiet which http ||
    python3 -m pip install --upgrade httpie &&
    export http=http

  quiet which htmlq ||
    printf "You need to install htmlq.\n"

  quiet which xh &&
    export http=xh
}


getMirrors() {
  $http --body --follow "$LIST_URL" \
    | htmlq "$SELECTOR" --attribute href \
    | grep -i "$PROTO:"
}


checkRepo() {
  local url="$1"
  
  quiet $http "$url" \
    --quiet --quiet \
    --timeout $MAX_TIME \
    --verify=no \
    --ignore-stdin \
    --follow \
    --headers \
    --check-status
}
export -f checkRepo


testMirror() {
  local url="$1"
  local fullUrl="$url/$URL_PATH"

  checkRepo "$fullUrl" &&
    printf "Valid: %s\n" "$url"
}
export -f testMirror


testMirrors() {
  parallel --will-cite -j "$JOBS" testMirror
}


main() {
  getDependencies &&
    getMirrors | testMirrors
}


main
