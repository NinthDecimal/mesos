FROM flower.jiwiredev.com:5000/nined/mapr4-client:latest
MAINTAINER fi@ninthdecimal.com

# see https://mesosphere.io/learn/install_ubuntu_debian/#step-0

WORKDIR /tmp
ENV BUILD_MESOS_VERSION 0.26.0

# Fix missing library the Ubuntu Apache Maven 3 distribution
# https://github.com/airbnb/chronos/issues/211
RUN echo "APT update 2015-06-07" \
 && apt-get update \
 && apt-get install -y \
    build-essential libyaml-dev libmysqlclient-dev libsqlite3-dev python-snappy python-boto python-dev libcurl4-nss-dev \
    libsasl2-dev libsasl2-2 libsasl2-modules maven autoconf libtool \
 && apt-get -y autoremove \
 && apt-get -y clean all \
 && apt-get -y autoclean all \
 && rm -fr /tmp/* /var/tmp/ /root/.m2 \
 && cd /usr/share/maven/lib \
 && wget http://central.maven.org/maven2/commons-lang/commons-lang/2.6/commons-lang-2.6.jar


RUN apt-get install -y libapr1 libsvn1 libapr1-dev libsvn-dev \
                       mysql-client postgresql-client libevent-dev git subversion \
 && apt-get -y autoremove \
 && apt-get -y clean all \
 && apt-get -y autoclean all \
 && rm -fr /tmp/* /var/tmp/

# install libnl from source so that we can enable network monitoring in mesos
RUN cd /tmp \
 && wget 'http://launchpad.net/ubuntu/+archive/primary/+files/libnl3_3.2.26.orig.tar.gz' \
 && tar xvfz libnl3_3.2.26.orig.tar.gz \
 && apt-get install -y bison flex \
 && cd libnl-3.2.26 \
 && ./configure && make && make install \
 && cd / \
 && rm -fr /tmp/*

 # make the headers visible to the mesos build
RUN cd /usr/include \
 && ln -s /usr/local/include/libnl3

# copy local checkout into /opt
ADD . /opt

WORKDIR /opt

# configure
RUN ./bootstrap
RUN rm -fr build && mkdir build && cd build && ../configure

WORKDIR /opt/build

# build and cleanup in a single layer
RUN ../configure --with-network-isolator \
 && make -j`/usr/bin/nproc` \
 && make install \
 && apt-get remove -y libapr1-dev libsvn-dev \
 && apt-get -y autoremove \
 && apt-get -y clean all \
 && apt-get -y autoclean all \
 && cd / && rm -rf /opt
