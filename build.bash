#!/usr/bin/env bash

set -xe

DIR="$(dirname "$(readlink -f "$0")")"

BUILDER="${BUILDER:-podman}"

${BUILDER} build "${DIR}" -f "${DIR}/Dockerfile" --build-arg ref="${SEAWEED_REF:-master}" -t quay.io/cryostat/cryostat-storage:latest
