#!/usr/bin/env bash

TEXT_RESET='\033[0m'
TEXT_RED='\033[0;31m'
TEXT_GREEN='\033[0;32m'
distros=( amazonlinux:2022 debian:bookworm centos:7 redhat/ubi8:8.6 ubuntu:22.10 )

for distro in "${distros[@]}"; do
  echo "running test for $distro"
  docker run --rm -v $PWD/docs/.vuepress/public/installer.sh:/tmp/installer.sh $distro /bin/sh -c "apt-get update; apt-get install curl -y; yum install tar gzip -y; cd /tmp && sh ./installer.sh" &>/dev/null && echo -e "$distro ${TEXT_GREEN}passed${TEXT_RESET}" || echo -e "$distro ${TEXT_RED}failed${TEXT_RESET}" &
done

FAIL=0
for job in $(jobs -p); do
  wait "$job" || (( "FAIL+=1" ))
done

if [ "$FAIL" == "0" ]; then
  echo -e "${TEXT_GREEN}All distros succeeded${TEXT_RESET}"
  exit 0
else
  echo -e "${TEXT_RED}Distros failed: $FAIL${TEXT_RESET}"
  exit 1
fi
