FROM ubuntu:18.04

ENV PATH $PATH:/root/pkg/bin/:root/pkg/sbin
ENV PATH $PATH:/usr/bin:/usr/sbin/:/usr/cross/bin:/usr/cross/sbin
ENV SH /bin/bash

RUN apt-get update
RUN DEBIAN_FRONTEND=nointeractive apt-get -y upgrade
RUN DEBIAN_FRONTEND=nointeractive apt-get install -y  cmake ninja-build gperf \
    ccache dfu-util device-tree-compiler wget \
    python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
    make gcc gcc-multilib \
    locales \
    clang-format
RUN DEBIAN_FRONTEND=nointeractive apt-get -y install libc-dev git bash openssl g++
RUN DEBIAN_FRONTEND=nointeractive apt-get -y install build-essential libncurses-dev
RUN apt-get install -y autoconf automake libtool autoconf-doc libtool-doc
RUN pip3 install cmake west requests docopt

RUN wget ftp://ftp.netbsd.org/pub/pkgsrc/pkgsrc-2020Q1/pkgsrc-2020Q1.tar.gz
RUN tar -xvf pkgsrc-2020Q1.tar.gz 
RUN cd pkgsrc/bootstrap && ./bootstrap --unprivileged

RUN cd pkgsrc/security/gnupg2 && bmake install
RUN cd pkgsrc/textproc/gsed && bmake install
RUN cd pkgsrc/devel/gmp && bmake install
RUN cd pkgsrc/math/mpfr && bmake install
RUN cd pkgsrc/math/mpcomplex && bmake install
RUN cd pkgsrc/math/isl && bmake install

RUN wget ftp://ftp.jaist.ac.jp/pub/GNU/binutils/binutils-2.34.tar.xz
RUN tar -xvf binutils-2.34.tar.xz
RUN rm -rf binutils-obj && mkdir binutils-obj && cd binutils-obj \
    && ../binutils-2.34/configure --prefix=/usr/cross --disable-nls --target=avr
RUN cd binutils-obj && make && make install && rm -rf ../binutils-obj && rm -rf ../binutils-2.34
RUN wget ftp://ftp.jaist.ac.jp/pub/GNU/gcc/gcc-9.3.0/gcc-9.3.0.tar.xz
RUN tar -xvf gcc-9.3.0.tar.xz
RUN export LDFLAGS="-Wl,-L/root/pkg/lib -Wl,-R/root/pkg/lib" && rm -rf gcc-obj && mkdir gcc-obj && cd gcc-obj \
    && ../gcc-9.3.0/configure --prefix=/usr/cross --with-gmp=/root/pkg --with-mpfr=/root/pkg --with-mpc=/root/pkg \
    --target=avr --disable-nls --enable-languages="c,c++"
RUN cd gcc-obj && make && make install && rm -rf ../gcc-obj && rm -rf ../gcc-9.3.0
RUN git clone https://github.com/stevenj/avr-libc3
RUN cd avr-libc3 && ./bootstrap && ./configure --prefix=/usr/cross --host=avr && make && make install
RUN mv avr-libc3/include/avr/io /usr/cross/avr/include/avr/ && mv avr-libc3/include/avr/legacyio /usr/cross/avr/include/avr/ \
    rm -rf avr-libc3
