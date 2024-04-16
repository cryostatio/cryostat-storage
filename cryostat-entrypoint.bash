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

function waitForStartup() {
    echo "cluster.check" | timeout "${BUCKET_CREATION_STARTUP_SECONDS:-30}"s weed shell 1>/dev/null 2>/dev/null || true
    sleep "${BUCKET_CREATION_DELAY_SECONDS:-5}"
}

function createBucket() {
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

VOLUME_MIN=40
NUM_VOLUMES=$(( VOLUME_MAX > VOLUME_MIN ? VOLUME_MAX : VOLUME_MIN ))
DATA_DIR="${DATA_DIR:-/tmp}"
AVAILABLE_DISK_BYTES="$(df -P -B1 "${DATA_DIR}" | tail -1 | tr -s ' ' | cut -d' ' -f 4)"
STORAGE_CAPACITY=${STORAGE_CAPACITY:-${AVAILABLE_DISK_BYTES}}
STORAGE_CAPACITY_BYTES=$(echo "${STORAGE_CAPACITY}" | numfmt --from=iec --suffix=B | tr -d 'B')
VOLUME_SIZE_BYTES=$(( "${STORAGE_CAPACITY_BYTES}" / "${NUM_VOLUMES}" ))

exec weed -logtostderr=true server \
    -dir="${DATA_DIR}" \
    -volume.max=${NUM_VOLUMES} \
    -volume.fileSizeLimitMB="${FILE_SIZE_LIMIT_MB:-4096}" \
    -master.volumeSizeLimitMB="$(( "${VOLUME_SIZE_BYTES}" / 1024 / 1024 ))" \
    -master.volumePreallocate="${VOLUME_PREALLOCATE:-false}" \
    -s3 -s3.config="${cfg}" \
    "$@"
