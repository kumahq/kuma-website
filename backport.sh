#!/bin/bash

# Inspired by https://blog.soltysiak.it/en/2017/08/how-to-use-git-patch-system-to-apply-changes-into-another-folder-structure/
# A script to backport changes from a release to a list of other release


set -e
if [[ $# -le 1 ]]; then
  echo "Backport a doc change from one directory to others"
  echo "Add the changes you want to backport to the staging area"
  echo "./backport.sh <origin> <dest1> <dest2>"
  exit 1
fi
if [[ ! -d app/docs/${1} ]]; then
  echo "app/docs/${1} is not an existing folder"
  exit 1
fi
git diff --patch --cached app/docs/${1} > /tmp/kuma-website.patch
trap "rm -rf /tmp/kuma-website.patch" EXIT

for var in "$@"; do
  if [[ ! -d app/docs/${var} ]]; then
    echo "no such doc version: app/docs/${var}"
    exit 1
  fi
  if [[ "${var}" != "${1}" ]]; then
    git apply -p4 --directory app/docs/$var /tmp/kuma-website.patch
  fi
done
