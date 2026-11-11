ARG ref=master

FROM registry.access.redhat.com/ubi9/ubi:9.7-1771346757 AS builder
ARG ref
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $ref https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.7-1779771821@sha256:03b67880096c45fbad58a50a5710bd31c3bcfce44f75da95ee6177dc269a72ef
ARG ref
LABEL seaweedfs.version=$ref
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
