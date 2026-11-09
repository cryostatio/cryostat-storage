ARG builder_version=8.10@sha256:05c0ec191769962e3aa08b7b90783bb64a1ba1c6f497b1fadb6afb90b16b4df7
ARG runner_version=8.10@sha256:ad379bd4c38c783c2196dfe5267006b7c0890858bc0b597043081f3fca9a0462
ARG ref=master
ARG goversion=1.22.6

FROM registry.access.redhat.com/ubi8/ubi:${builder_version} AS builder
ARG ref
ARG goversion
RUN dnf install -y go git make gettext \
    && go install golang.org/dl/go$goversion@latest \
    && ~/go/bin/go$goversion download \
    && mkdir -p ~/bin \
    && ln -s ~/go/bin/go$goversion ~/bin/go \
    && export PATH="$HOME/bin:$PATH" \
    && pushd /root \
    && git clone --depth 1 --branch $ref https://github.com/seaweedfs/seaweedfs \
    && pushd seaweedfs/weed \
    && make install \
    && popd \
    && popd

FROM registry.access.redhat.com/ubi8/ubi-micro:${runner_version}
ARG ref
ARG goversion
LABEL seaweedfs.version=$ref golang.version=$goversion
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
