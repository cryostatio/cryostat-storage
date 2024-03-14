ARG builder_version=8.9
ARG runner_version=8.9
ARG ref=master

FROM registry.access.redhat.com/ubi8/ubi:${builder_version} AS builder
ARG ref
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $ref https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi8/ubi-micro:${runner_version}
ARG ref
LABEL seaweedfs.version=$ref
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
