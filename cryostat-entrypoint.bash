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

VOLUME_MIN=${VOLUME_MIN:-40}
NUM_VOLUMES=$(( ${VOLUME_MAX:-0} > VOLUME_MIN ? VOLUME_MAX : VOLUME_MIN ))
DATA_DIR="${DATA_DIR:-/tmp}"

# if the user specifies a STORAGE_CAPACITY they may specify it in raw byte count, or byte count with a B suffix, or
# using other suffices like '50MB'. If the user does not specify it then we use df to check the available space on the
# disk in raw byte count and attempt to fill all available space, or fill the maximum space that we are able to given
# the individual volume size limit and the maximum number of volumes we will create.
# The usage of numfmt here allows us to accept this flexible input and convert it to a byte count, then use tr to
# remove the B suffix.
STORAGE_CAPACITY=${STORAGE_CAPACITY:-"$(df -P -B1 "${DATA_DIR}" | tail -1 | tr -s ' ' | cut -d' ' -f 4)"}
STORAGE_CAPACITY_BYTES=$(echo "${STORAGE_CAPACITY}" | numfmt --from=iec --suffix=B | tr -d 'B')

VOLUME_SIZE_BYTES=$(( "${STORAGE_CAPACITY_BYTES}" / "${NUM_VOLUMES}" ))
VOLUME_SIZE_BYTES_MAX=31457280000 # 30000MB, the maximum volume size SeaweedFS will create
VOLUME_SIZE_BYTES=$(( VOLUME_SIZE_BYTES > VOLUME_SIZE_BYTES_MAX ? VOLUME_SIZE_BYTES_MAX : VOLUME_SIZE_BYTES ))

FLAGS=(
    "-filer.allowedOrigins=${FILER_ORIGINS:-0.0.0.0}"
)

if [ "${DIR_LISTING_ENABLE:-0}" != 1 ]; then
    FLAGS+=(
        "-filer.exposeDirectoryData=false"
        "-filer.disableDirListing"
        "-webdav=false"
    )
fi

if [ "${REST_ENCRYPTION_ENABLE:-1}" = 1 ]; then
    FLAGS+=("-filer.encryptVolumeData")
fi

exec weed -logtostderr=true server \
    -dir="${DATA_DIR}" \
    -volume.max=${NUM_VOLUMES} \
    -volume.fileSizeLimitMB="${FILE_SIZE_LIMIT_MB:-4096}" \
    -master.volumeSizeLimitMB="$(( "${VOLUME_SIZE_BYTES}" / 1024 / 1024 ))" \
    -master.volumePreallocate="${VOLUME_PREALLOCATE:-false}" \
    ${FLAGS[*]} \
    -s3 -s3.config="${cfg}" \
    "$@"
