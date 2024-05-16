FROM       scratch
ARG        TARGETARCH
ENV        TARGETARCH=$TARGETARCH
COPY       dist/$TARGETARCH/rqotdd /rqotdd
WORKDIR    /
ENTRYPOINT ["/rqotdd"]
EXPOSE     17/tcp 17/udp 787/tcp
