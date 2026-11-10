ARG ref=master

FROM registry.access.redhat.com/ubi9/ubi:9.7-1779771855@sha256:e9a31af6530caffa3551f266c51a0d43b602e8f76a0dc12826dbeebceb487c92 AS builder
ARG ref
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $ref https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.7-1771346390
ARG ref
LABEL seaweedfs.version=$ref
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
