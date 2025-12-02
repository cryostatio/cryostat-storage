ARG ref=master
ARG goversion=1.22.12

FROM registry.access.redhat.com/ubi9/ubi:9.6 AS builder
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

FROM registry.access.redhat.com/ubi9/ubi-micro:9.6
ARG ref
ARG goversion
LABEL seaweedfs.version=$ref golang.version=$goversion
COPY --from=builder /usr/bin/envsubst /root/go/bin/weed /usr/bin/
COPY ./cryostat-entrypoint.bash /usr/bin/
COPY seaweed_conf.template.json /etc/seaweed_conf.template.json
USER 185
ENTRYPOINT ["/usr/bin/cryostat-entrypoint.bash"]
