#!/bin/sh

# Copyright 2019-2024 Kong Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# You can customize the version of Kuma (or Kuma-based products) to
# download by setting the VERSION environment variable, and you can change
# the default 64bit architecture by setting the ARCH variable.

set -eu

if [ -n "${VERBOSE:-}" ]; then
  set -x
fi

log() {
  # Print to stderr to support --print-version being the only stdout output
  printf >&2 "%s\t%s\n" "${2:-INFO}" "$1"
}

err() {
  log "$1" 'ERROR'
  exit 1
}

main() {

  DIR="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)"

  : "${ARCH:=$(uname -m)}"
  : "${BRANCH:=master}"
  : "${CTL_NAME:=kumactl}"
  : "${PRODUCT_NAME:=Kuma}"
  : "${REPO:=kumahq/kuma}"
  : "${VERSION:=latest}"
  : "${LATEST_VERSION:=https://kuma.io/latest_version}"
  : "${OS:=$(uname -s | tr '[:upper:]' '[:lower:]')}"

  OS="${OS:-linux}"
  DISTRO="${DISTRO:-$OS}"

  log "Welcome to the ${PRODUCT_NAME} automated download!"

  case "_${OS}" in
  _darwin) true ;;
  _linux)
    DISTRO="${DISTRO:-$(
      grep -E '^ID=.*' /etc/os-release |
        cut -d'=' -f2 |
        tr -d '"' |
        tr -d \' |
        tr '[:upper:]' '[:lower:]'
    )}"

    if [ "$DISTRO" = 'amzn' ]; then
      DISTRO='centos'
    fi
    ;;
  _ | _*) err "Operating system ${OS} not supported by ${PRODUCT_NAME}." ;;
  esac

  case "_${ARCH}" in
  _amd64 | _x86_64)
    ARCH='amd64'
    ;;
  _aarch64* | _arm64 | _armv8*)
    ARCH='arm64'
    ;;
  _ | _*) err "Architecture ${ARCH} not supported by ${PRODUCT_NAME}" ;;
  esac

  missing=''
  for tool in curl grep gzip tar; do
    if ! command -v $tool >/dev/null 2>&1; then
      missing="${missing:+${missing} }${tool}"
    fi
  done

  if [ -n "$missing" ]; then
    err "Required tools cannot be found: ${missing}."
  fi

  if [ "$VERSION" = 'latest' ]; then
    log "Fetching latest ${PRODUCT_NAME} version.."

    LATEST_VERSION="$(curl -f -sL "$LATEST_VERSION")"
    if [ -z "$LATEST_VERSION" ]; then
      err "Unable to determine latest ${PRODUCT_NAME} version, tried: ${LATEST_VERSION}"
    fi
    VERSION="$LATEST_VERSION"
  fi

  FILENAME_VERSION="${VERSION}"

  if [ "$VERSION" = 'preview' ]; then

    if ! command -v gh >/dev/null 2>&1; then
      err "Must have github's gh CLI installed to install a preview version."
    fi

    log "Fetching latest preview commit.."
    commit=$(gh run list --repo "${REPO}" --branch "${BRANCH}" --workflow build-test-distribute -L 200 --json event,headSha,conclusion --jq '[.[] | select(.conclusion == "success" and .event == "push")] | first | .headSha[0:9]')
    if ! echo "$commit" | grep -qs -E '[a-z0-9]{9,}'; then
      err "Failed to find suitable preview commit (${count} commits checked)."
    fi
    log "Found preview commit: https://github.com/${REPO}/commit/${commit}"

    VERSION="$commit"
    FILENAME_VERSION="0.0.0-preview.v${commit}"
  fi

  if [ $# -gt 0 ]; then
    case $1 in
    --print-version)
      echo "${FILENAME_VERSION}"
      exit 0
      ;;
    *)
      err "Invalid arguments."
      ;;
    esac
  fi

  log "${PRODUCT_NAME} version: ${FILENAME_VERSION}"
  log "${PRODUCT_NAME} architecture: ${ARCH}"
  log "Operating system: ${OS}"
  if [ "$OS" = 'linux' ]; then
    log "Distribution: ${DISTRO}"
  fi

  TARGET_NAME="$PRODUCT_NAME"

  # Example Cloudsmith URLs
  # https://packages.konghq.com/public/kuma-binaries-preview/raw/names/kuma-darwin-arm64/versions/6f6e380ae/kuma-0.0.0-preview.v6f6e380ae-darwin-arm64.tar.gz
  # https://packages.konghq.com/public/kong-mesh-binaries-release/raw/names/kong-mesh-windows-amd64/versions/2.5.1/kong-mesh-2.5.1-windows-amd64.tar.gz
  # https://packages.konghq.com/public/kong-mesh-binaries-release/raw/names/kong-mesh-linux-arm64/versions/2.5.1/kong-mesh-2.5.1-linux-arm64.tar.gz
  # https://packages.konghq.com/public/kuma-legacy/raw/names/kumactl-linux-amd64/versions/1.8.1/kumactl-1.8.1-linux-amd64.tar.gz

  URL='https://packages.konghq.com/public'
  REPO_REPO="${REPO##*/}"
  URL_REPO="${REPO_REPO}-binaries-release"

  # populate major/minor/patch using read builtin
  # shellcheck disable=SC2034
  IFS=. read -r major minor patch <<-EOF
${VERSION}
EOF

  if echo "$FILENAME_VERSION" | grep -qs -E 'preview|0.0.0'; then
    URL_REPO="${REPO_REPO}-binaries-preview"
    VERSION="${FILENAME_VERSION#*0.0.0-preview.v}"
  else

    # 2.1.x or lower
    if {
      [ "$major" = '2' ] && [ "$minor" -lt '2' ]
    } || [ "$major" -le '1' ]; then
      URL_REPO="${REPO_REPO}-legacy"

      # kuma and ( 1.7.x or newer )
      if [ "$REPO_REPO" = 'kuma' ] && {
        [ "$major" -gt '1' ] || {
          [ "$major" -ge '1' ] && [ "$minor" -ge '7' ]
        }
      }; then
        log "We only compile ${CTL_NAME} for your Linux distribution."

        TARGET_NAME='kumactl'
        REPO_REPO='kumactl'
      fi
    fi
  fi

  # kuma-darwin-arm64
  # kong-mesh-windows-amd64
  # kong-mesh-linux-arm64
  # kumactl-linux-amd64
  URL_NAME="${REPO_REPO}-${DISTRO}-${ARCH}"

  # kuma-0.0.0-preview.v6f6e380ae-darwin-arm64.tar.gz
  # kong-mesh-2.5.1-windows-amd64.tar.gz
  # kong-mesh-2.5.1-linux-arm64.tar.gz
  # kumactl-1.8.1-linux-amd64.tar.gz
  URL_FILENAME="${REPO_REPO}-${FILENAME_VERSION}-${DISTRO}-${ARCH}.tar.gz"

  URL="${URL}/${URL_REPO}/raw/names/${URL_NAME}/versions/${VERSION}/${URL_FILENAME}"

  if ! curl --fail --silent --head "$URL" >/dev/null; then
    err "Unable to download ${TARGET_NAME} at the following URL: ${URL}"
  fi

  log "Downloading ${TARGET_NAME} from: ${URL}"

  if curl --fail -L "$URL" | tar xz; then
    log "${TARGET_NAME} ${FILENAME_VERSION} has been downloaded!"

    if [ "$TARGET_NAME" != "$CTL_NAME" ]; then

      # correct for discrepancies in $0 between invocation types:
      #   - curl | sh (piped)
      #   - ./app/installer.sh (shebang)
      #   - sh app/installer.sh (sh argument)
      # argument invocation
      if [ "$(basename "$DIR")" = 'app' ]; then
        DIR="$(dirname "$DIR")"
      fi

      cat "${DIR}/${REPO_REPO}-${FILENAME_VERSION}/README"
    fi
  else
    err "Unable to download ${TARGET_NAME}"
  fi
}

main "$@"
