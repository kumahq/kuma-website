#!/bin/sh

# Copyright 2019-2020 Kong Inc.
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

# You can customize the version of Kuma to download by setting the
# KUMA_VERSION environment variable, and you can change the default 64bit
# architecture by setting the KUMA_ARCH variable.

: "${KUMA_VERSION:=}"
: "${KUMA_ARCH:=amd64}"

DISTRO=""

printf "\n"
printf "INFO\tWelcome to the Kuma automated download!\n"

if ! type "grep" > /dev/null 2>&1; then
  printf "ERROR\tgrep cannot be found\n"
  exit 1;
fi
if ! type "curl" > /dev/null 2>&1; then
  printf "ERROR\tcurl cannot be found\n"
  exit 1;
fi
if ! type "tar" > /dev/null 2>&1; then
  printf "ERROR\ttar cannot be found\n"
  exit 1;
fi

OS=`uname -s`
if [ "$OS" = "Linux" ]; then
  DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
elif [ "$OS" = "Darwin" ]; then
  DISTRO="darwin"
else
  printf "ERROR\tOperating system %s not supported by Kuma\n" "$OS"
  exit 1
fi

if [ -z "$DISTRO" ]; then
  printf "ERROR\tUnable to detect the operating system\n"
  exit 1
fi

if [ -z "$KUMA_VERSION" ]; then
  # Fetching latest Kuma version
  printf "INFO\tFetching latest Kuma version..\n"
  KUMA_VERSION=`curl -s https://kuma.io/latest_version`
  if [ $? -ne 0 ]; then
    printf "ERROR\tUnable to fetch latest Kuma version.\n"
    exit 1
  fi
  if [ -z "$KUMA_VERSION" ]; then
    printf "ERROR\tUnable to fetch latest Kuma version because of a problem with Kuma.\n"
    exit 1
  fi
fi

printf "INFO\tKuma version: %s\n" "$KUMA_VERSION"
printf "INFO\tKuma architecture: %s\n" "$KUMA_ARCH"
printf "INFO\tOperating system: %s\n" "$DISTRO"

URL="https://kong.bintray.com/kuma/kuma-$KUMA_VERSION-$DISTRO-$KUMA_ARCH.tar.gz"

if ! curl -s --head $URL | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
  printf "ERROR\tUnable to download Kuma at the following URL: %s\n" "$URL"
  exit 1
fi

printf "INFO\tDownloading Kuma from: %s" "$URL"
printf "\n\n"

if curl -L "$URL" | tar xz; then
  printf "\n"
  printf "INFO\tKuma %s has been downloaded!\n" "$KUMA_VERSION"
  # TODO: Add quickstart instructions
else
  printf "\n"
  printf "ERROR\tUnable to download Kuma\n"
  exit 1
fi
