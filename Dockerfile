ARG SEAWEED_VERSION=4.36

FROM registry.access.redhat.com/ubi9/ubi:9.8-1782365825@sha256:37a15896602263cb998cd3c21919efb433adf9dbd3a7c961da5d8e3083a0db82 AS builder
ARG SEAWEED_VERSION
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $SEAWEED_VERSION https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.8-1779858820@sha256:b498b3ea26111ab4b81d65139f2ebd2ef9a2abb7a4588b7fdcc54889f95e9caa
ARG SEAWEED_VERSION
LABEL seaweedfs.version=$SEAWEED_VERSION
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
