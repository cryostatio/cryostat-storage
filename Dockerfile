FROM docker.io/minio/minio:latest

ENV MINIO_USER minio
ENV MINIO_UID_GID 5001

RUN echo "${MINIO_USER}:x:${MINIO_UID_GID}:${MINIO_UID_GID}:${MINIO_USER}:/home/${MINIO_USER}:/sbin/nologin" >> /etc/passwd && \
    echo "${MINIO_USER}:x:${MINIO_UID_GID}:" >> /etc/group && \
    mkdir "/home/${MINIO_USER}"

USER 5001
