#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

BUILDER="${BUILDER:-podman}"

source versions.env

${BUILDER} build "${DIR}" -f "${DIR}/Dockerfile" --build-arg ref="${SEAWEED_VERSION:-master}" -t quay.io/cryostat/cryostat-storage:latest
