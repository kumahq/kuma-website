#!/bin/bash

# Inspired by https://blog.soltysiak.it/en/2017/08/how-to-use-git-patch-system-to-apply-changes-into-another-folder-structure/
# A script to backport changes from a release to a list of other release


set -e
if [[ $# -le 1 ]]; then
  echo "backport a doc change from one directory to others"
  echo "./backport.sh <origin> <dest1> <dest2>"
  exit 1
fi
if [[ ! -d docs/docs/${1} ]]; then
  echo "docs/docs/${1} is not an existing folder"
  exit 1
fi
git diff --patch --cached docs/docs/${1} > /tmp/kuma-website.patch
trap "rm -rf /tmp/kuma-website.patch" EXIT

for var in "$@"; do
  if [[ ! -d docs/docs/${var} ]]; then
    echo "no such doc version: docs/docs/${var}"
    exit 1
  fi
  if [[ "${var}" != "${1}" ]]; then
    git apply -p4 --directory docs/docs/$var /tmp/kuma-website.patch
  fi
done
