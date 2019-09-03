#!/bin/bash
set -e

cd "$(dirname $0)"

ubuntu() {
  cd ubuntu

  dirs() {
    BASE_DIR=$1
    echo $BASE_DIR
    while read DOTNET_CORE_VERSION na; do
      echo $BASE_DIR/dotnet/core/$DOTNET_CORE_VERSION
    done < <(cat derived/dotnet/core/versions | sed '/^\s*#/d')
  }

  while read UBUNTU_VERSION na; do
    echo "ubuntu/$UBUNTU_VERSION"
    while read AZDO_AGENT_RELEASE na; do
      dirs ubuntu/$UBUNTU_VERSION/${AZDO_AGENT_RELEASE/-/\/}
    done < <(cat versioned/releases | sed '/^\s*#/d')
  done < <(cat versions | sed '/^\s*#/d')

  cd ..
}

ubuntu
