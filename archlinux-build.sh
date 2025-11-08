#!/bin/bash

cd $(dirname $0)

set -euo pipefail

if [[ ${DEBUG:-} != "" ]]; then
    set -x
fi

type wget
type packer

export WORKING_DIR=$(pwd)
export ARCHLINUX_QCOW2_URL=${ARCHLINUX_QCOW2_URL:-"https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2"}
export ARCHLINUX_QCOW2_SHA256SUM_URL=${ARCHLINUX_QCOW2_SHA256SUM_URL:-"https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2.SHA256"}
export IMAGE_NAME="Arch-Linux-x86_64-basic.qcow2"
export DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-arch}
export DATETIME=$(date +"%Y%m%d")
export DEBUG=${DEBUG:-}

mkdir -p tmp && cd tmp

if [[ -e "${IMAGE_NAME}" ]]; then
    echo "${IMAGE_NAME} already exists, skip download."
else
    echo "Downloading image ${IMAGE_NAME}."
    wget -c ${ARCHLINUX_QCOW2_URL} -O ${IMAGE_NAME}.tmp
    wget -c ${ARCHLINUX_QCOW2_SHA256SUM_URL} -O ${IMAGE_NAME}.SHA256
    mv ${IMAGE_NAME}.tmp ${IMAGE_NAME}
fi

cd ../config

packer init archlinux-x86_64.pkr.hcl
packer build archlinux-x86_64.pkr.hcl
