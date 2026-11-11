ARG SEAWEED_VERSION=4.53

FROM registry.access.redhat.com/ubi9/ubi:9.9-1793830043@sha256:8b212f75a0e5a156ac28b1c5c030d2e8a07715254e19d522286118279399af81 AS builder
ARG SEAWEED_VERSION
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $SEAWEED_VERSION https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.8-1794184668@sha256:d3499a0896e2d6a1642f922615831bc5c2fd513bbb34f3446cabba530d9d54a2
ARG SEAWEED_VERSION
LABEL seaweedfs.version=$SEAWEED_VERSION
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
