#!/usr/bin/env bash

DIR="$(dirname "$(readlink -f "$0")")"

BUILDER="${BUILDER:-podman}"

${BUILDER} build "${DIR}" -f "${DIR}/Dockerfile" -t quay.io/cryostat/cryostat-storage:latest
