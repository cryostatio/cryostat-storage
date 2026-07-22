ARG SEAWEED_VERSION=4.40

FROM registry.access.redhat.com/ubi9/ubi:9.8-1784720169@sha256:2a6bd6971e6026177b2439655282660519198870e9063c4a03a208de88be2e9e AS builder
ARG SEAWEED_VERSION
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $SEAWEED_VERSION https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.8-1784702951@sha256:b1e86b97028b8fcfb6d85f997c39e6b6b67496163ef8d80d243220a4918e8bef
ARG SEAWEED_VERSION
LABEL seaweedfs.version=$SEAWEED_VERSION
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
