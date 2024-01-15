ARG builder_version=8.9
ARG runner_version=8.9

FROM registry.access.redhat.com/ubi8/ubi:${builder_version} AS builder
ARG ref=master
RUN dnf install -y go git make gettext \
    && git clone --depth 1 --branch $ref https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install

FROM registry.access.redhat.com/ubi8/ubi-micro:${runner_version}
COPY --from=builder /usr/bin/envsubst /usr/bin/
COPY --from=builder /root/go/bin/weed /usr/local/bin/weed
COPY ./entrypoint.bash /usr/local/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
ENTRYPOINT ["/usr/local/entrypoint.bash"]
