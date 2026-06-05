# syntax=docker/dockerfile:1
# FOR REFERENCE ONLY, SEE README.md
FROM ubuntu:noble
LABEL MAINTAINER="Darktrace Ltd <opensource@darktrace.com>"

# Copy over files
COPY docker-entrypoint.sh ./

# Update apt and install required packages
ARG ARCH
RUN --mount=type=bind,target=/packages,source=. apt-get update \
    && apt-get install -y /packages/*${ARCH}.deb iproute2 net-tools iputils-ping \
    && apt-get clean

# Must run as root
# kics-scan ignore-line
USER root

# Run osSensor
ENTRYPOINT ["./docker-entrypoint.sh"]
