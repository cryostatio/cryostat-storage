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

function createBuckets() {
    for i in $(echo "$CRYOSTAT_BUCKETS" | tr ',' '\n'); do
        local len
        len="${#i}"
        if [ "${len}" -lt 3 ]; then
            echo "Bucket names must be at least 3 characters"
            exit 1
        fi
        if [ "${len}" -gt 63 ]; then
            echo "Bucket names must be at most 63 characters"
            exit 1
        fi
        local cmd
        # FIXME do something better than sleeping here
        cmd="sleep ${BUCKET_CREATION_STARTUP_SECONDS:-30} ; echo \"s3.bucket.create -name ${i}\" | weed shell"
        bash -c "${cmd}" &
    done
}
createBuckets

exec /usr/bin/entrypoint.sh \
    server -dir="${DATA_DIR:-/tmp}" \
    -s3 -s3.config="${cfg}" \
    "$@"
