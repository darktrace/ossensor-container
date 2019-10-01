FROM docker-registry:443/ubuntu:xenial
MAINTAINER Darktrace Ltd <opensource@darktrace.com>

# Copy over files
COPY docker-entrypoint.sh *.deb dependencies.txt ./

# Update apt and install required packages
RUN sed -i.bak 's/[^\/]*.ubuntu.com/192.168.10.10/' /etc/apt/sources.list \
  && apt-get update && apt-get install -y @@DEPS@@ iproute2 net-tools iputils-ping \
  && dpkg -i *.deb \
  && chmod +x ./docker-entrypoint.sh \
  && rm *.deb \
  && rm -rf /var/lib/apt/lists/* \
  && mv  /etc/apt/sources.list.bak /etc/apt/sources.list

# Run osSensor
ENTRYPOINT ["./docker-entrypoint.sh"]