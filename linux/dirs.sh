#!/bin/bash
set -e

cd "$(dirname "$0")"

ubuntu() {
  cd ubuntu

  dirs() {
    BASE_DIR=$1
    echo "$BASE_DIR"
    while read -r DOTNET_CORE_VERSION; do
      echo "$BASE_DIR/dotnet/core/$DOTNET_CORE_VERSION"
    done < <(< derived/dotnet/core/versions sed '/^\s*#/d')
  }

  while read -r UBUNTU_VERSION; do
    echo "ubuntu/$UBUNTU_VERSION"
    while read -r AZDO_AGENT_RELEASE; do
      dirs "ubuntu/$UBUNTU_VERSION/${AZDO_AGENT_RELEASE/-/\/}"
    done < <(< versioned/releases sed '/^\s*#/d')
  done < <(< versions sed '/^\s*#/d')

  cd ..
}

ubuntu
