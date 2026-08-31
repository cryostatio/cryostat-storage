ARG SEAWEED_VERSION=4.44

FROM registry.access.redhat.com/ubi9/ubi:9.8-1788191706@sha256:f405b019ad4f6ebf9097b636e83b363b1f11afe26557b7896fabff954b65a1b8 AS builder
ARG SEAWEED_VERSION
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $SEAWEED_VERSION https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.8-1787778798@sha256:f332c99eb8f798a8486821c91937f10ad64ee83d7e739303be2df051040918f6
ARG SEAWEED_VERSION
LABEL seaweedfs.version=$SEAWEED_VERSION
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
