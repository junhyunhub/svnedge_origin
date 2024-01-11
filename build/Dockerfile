FROM ubuntu:22.04

LABEL vendor="CollabNet Engineering" \
      license="AGPL 3.0"
EXPOSE 18080
EXPOSE 3343

ARG S6_OVERLAY_VERSION=3.1.6.2

RUN useradd -u 1000 svnedge --create-home --shell /bin/bash

RUN apt-get update
# https://chloe-codes1.gitbook.io/til/linux/ubuntu/setting_a_java_home_path_in_ubuntu
# openjdk-8-jre
RUN apt-get install -y openjdk-8-jdk-headless curl vim zip unzip xz-utils net-tools tree build-essential checkinstall python2.7-minimal python3 && \
    apt-get clean

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1
RUN update-alternatives --install /usr/bin/python2 python2 /usr/bin/python2.7 1
#RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3 1

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Install s6 init system
# https://github.com/just-containers/s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
ENTRYPOINT ["/init"]

# Install scripts
ADD s6-services/* ./etc

# Install SVN Edge
ADD CollabNetSubversionEdge-6.0.2-9_linux-x86_64.tar.gz /home/svnedge/
RUN mv /home/svnedge/csvn/data /home/svnedge/csvn/data-template




