#!/bin/bash
set -e
for i in docs/docs/*; do
  if [[ ! -d $i ]]; then continue; fi

  branch=`basename $i | sed 's/\(.*\)\.x/release-\1/g'`
  if [[ $branch == "dev" ]]; then
    branch="master"
  fi
  echo "Copying $branch"

  pushd ../kuma
    git checkout $branch
  popd
  if [[ ! -d ../kuma/docs/generated ]]; then
    echo "No generated docs, ignoring..."
    continue
  fi
  echo "Copying generated docs"
  rm -rf "${i}/generated"
  cp -r ../kuma/docs/generated "${i}/generated"
done
