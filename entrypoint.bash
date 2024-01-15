#!/usr/bin/env bash

if [ -z "${CRYOSTAT_ACCESS_KEY}" ]; then
    echo 'CRYOSTAT_ACCESS_KEY must be set and non-empty'
    exit 1
fi

if [ -z "${CRYOSTAT_SECRET_KEY}" ]; then
    echo 'CRYOSTAT_SECRET_KEY must be set and non-empty'
    exit 2
fi

set -xe

cfg="$(mktemp)"
envsubst '$CRYOSTAT_ACCESS_KEY $CRYOSTAT_SECRET_KEY' < /etc/seaweed_conf.template.json > "${cfg}"

exec /usr/local/bin/weed \
    server -dir="${DATA_DIR:-/data}" \
    -s3 -s3.config="${cfg}" \
    "$@"
