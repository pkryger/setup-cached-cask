#!/bin/bash

if [[ $# -eq 0  || $# -gt 2 ]]; then
   echo "Usage: $0 REPOSITORY_PATH [EMACS_VERSION]" >&2n
   exit 1
fi

set -euo pipefail

if [[ -z "${GITHUB_ACTION_PATH+x}" ]]; then
    GITHUB_ACTION_PATH=$(git rev-parse --show-toplevel)
fi

cd "${1}"

emacs_version=

if [[ $# -eq 2 ]]; then
    emacs_version=$(echo "${2}" \
                        | sed -e 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi

if [[ -z "${emacs_version}" ]]; then
    emacs_version=$(cask emacs --version \
                        | sed -ne 's/[[:space:]]//g;1s/.*Emacs//p')
elif [[ "${emacs_version}" == "snapshot" ]]; then
    emacs_version=$(git ls-remote https://github.com/purcell/nix-emacs-ci.git refs/heads/master \
                        | sed -e 's/^\([[:xdigit:]]\{7,7\}\).*/nix-emacs-ci@\1/ '\
                        | tr -d '\n')
fi

if [[ -z "${emacs_version}" ]]; then
    echo "Cannot get emacs version" >&2
    exit 1
fi

cask_sha=$(cask emacs -batch \
                --load "${GITHUB_ACTION_PATH}/cask-cache-hash.el" \
                --funcall cask-cache-hash)

if [[ -z "${cask_sha}" ]]; then
    echo "Cannot get cask sha" >&2
    exit 1
fi


key="cached-cask-packages-${emacs_version}-${cask_sha}"

echo "${key}" | tee /dev/stderr
