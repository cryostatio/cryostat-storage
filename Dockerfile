FROM registry.access.redhat.com/ubi8/ubi:8.9 AS builder
ARG ref=master
RUN dnf install -y go git make
RUN git clone --depth 1 --branch $ref https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install

FROM registry.access.redhat.com/ubi8/ubi-micro:8.9
COPY --from=builder /root/go/bin/weed /usr/bin/weed
ENTRYPOINT ["/usr/bin/weed"]
