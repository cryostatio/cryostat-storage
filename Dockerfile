ARG SEAWEED_VERSION=4.37

FROM registry.access.redhat.com/ubi9/ubi:9.8-1782365825@sha256:37a15896602263cb998cd3c21919efb433adf9dbd3a7c961da5d8e3083a0db82 AS builder
ARG SEAWEED_VERSION
RUN dnf install -y go git make gettext \
    && pushd /root \
    && git clone --depth 1 --branch $SEAWEED_VERSION https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi9/ubi-micro:9.8-1782363471@sha256:fdf68a4f5f88cca14ae906bbec6e0fbbffe92b5b91e73e0862c961234d63b986
ARG SEAWEED_VERSION
LABEL seaweedfs.version=$SEAWEED_VERSION
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
