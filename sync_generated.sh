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
  if [[ -f ../kuma/pkg/config/app/kuma-cp/kuma-cp.defaults.yaml ]]; then
    echo "Copying default"

    echo '# Control-Plane configuration
Here are all options to configure the control-plane:

```yaml' > "${i}/generated/kuma-cp.md"
    cat ../kuma/pkg/config/app/kuma-cp/kuma-cp.defaults.yaml >> "${i}/generated/kuma-cp.md"
    echo '```' >> "${i}/generated/kuma-cp.md"
  fi
done
