ARG SEAWEED_VERSION=4.48

FROM registry.access.redhat.com/ubi9/ubi:9.8-1793179168@sha256:5f08e80aa970ae77712e75e5e857ac0b396abc900823c4d041c1150a9538a13f AS builder
ARG SEAWEED_VERSION
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $SEAWEED_VERSION https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.8-1791895366@sha256:5be877a2a280ae36eb9ab80ca4efb28bbf77c57abbba38137cdc37a03b8465e6
ARG SEAWEED_VERSION
LABEL seaweedfs.version=$SEAWEED_VERSION
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
