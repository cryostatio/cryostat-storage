#!/usr/bin/env bash

if [ -z "${CRYOSTAT_ACCESS_KEY}" ]; then
    echo 'CRYOSTAT_ACCESS_KEY must be set and non-empty'
    exit 1
fi

if [ -z "${CRYOSTAT_SECRET_KEY}" ]; then
    echo 'CRYOSTAT_SECRET_KEY must be set and non-empty'
    exit 2
fi

set -x

cfg="$(mktemp)"
# shellcheck disable=SC2016
envsubst '$CRYOSTAT_ACCESS_KEY $CRYOSTAT_SECRET_KEY' < /etc/seaweed_conf.template.json > "${cfg}"

function waitForStartup() {
    while ! echo "cluster.check" | timeout 2s weed shell >/dev/null 2>&1 ; do
        echo "Waiting for cluster to be ready for bucket creation..."
        sleep "${BUCKET_CREATION_STARTUP_SECONDS:-10}"
    done
    echo "Cluster ready for bucket creation."
    sleep "${BUCKET_CREATION_DELAY_SECONDS:-${BUCKET_CREATION_STARTUP_SECONDS:-3}}"
}

function createBucket() {
    echo "Creating S3 bucket $1"
    echo "s3.bucket.create -name $1" | timeout "${BUCKET_CREATION_TIMEOUT_SECONDS:-5}"s weed shell
}

function createBuckets() {
    waitForStartup
    for name in "$@"; do
        createBucket "${name}"
    done
}

names=()
for i in $(echo "$CRYOSTAT_BUCKETS" | tr ',' '\n'); do
    len="${#i}"
    if [ "${len}" -lt 3 ]; then
        echo "Bucket names must be at least 3 characters"
        exit 1
    fi
    if [ "${len}" -gt 63 ]; then
        echo "Bucket names must be at most 63 characters"
        exit 1
    fi
    names+=("${i}")
done

createBuckets "${names[@]}" &

set -e

exec weed -logtostderr=true mini \
    -admin.ui=false \
    -filer.allowedOrigins="${FILER_ORIGINS:-0.0.0.0}" \
    -filer.encryptVolumeData \
    -filer.exposeDirectoryData=false \
    -filer.disableDirListing \
    -webdav=false \
    -s3.encryptVolumeData \
    -s3.config="${cfg}" \
    -dir="${DATA_DIR:-/tmp}" \
    "$@"
