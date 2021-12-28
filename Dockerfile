# Build stage for mussel toolchain
FROM debian:bullseye-slim as musl-toolchain

# Specify release variables
ARG TARGETARCH
ARG TARGETVARIANT
ARG RLS_OS=linux
ARG RLS_LIB=gnu
ARG RLS_ARCH=x86_64

# determine architecture, download release binary
# and verify against random OK signer and pinned shasums
RUN set -ex && ARCHITECTURE=$(dpkg --print-architecture) \
    && if [ "${ARCHITECTURE}" = "amd64" ]; then RLS_ARCH=x86_64 ; fi \
    && if [ "${ARCHITECTURE}" = "arm64" ]; then RLS_ARCH=aarch64; fi \
    && if [ "${ARCHITECTURE}" = "armhf" ]; then RLS_ARCH=arm && RLS_LIB=gnueabihf; fi \
    && if [ "${ARCHITECTURE}" = "i386" ]; then RLS_ARCH=i686-pc; fi \
    && if [ "${RLS_ARCH}" = "" ]; then echo "Could not determine architecture" >&2; exit 1; fi \
    && echo ${RLS_ARCH}-${RLS_OS}-${RLS_LIB} >> host.txt

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git \
  bash \
  bc \
  binutils \
  bison \
  libbison-dev \
  bzip2 \
  build-essential \
  ccache \
  coreutils \
  diffutils \
  findutils \
  gawk \
  git \
  grep \
  gzip \
  libarchive-dev \
  libarchive-tools \
  libc6 \
  lzip \
  libzstd-dev \
  m4 \
  make \
  perl \
  pv \
  rsync \
  sed \
  texinfo \
  wget \
  xz-utils \
  zstd

RUN ln -s /lib/$(cat host.txt)/libc.so.6 /lib/libc.so.6

COPY check.sh mussel.sh /mussel/

WORKDIR /mussel

RUN ./check.sh

ENV PKG_CONFIG_PATH=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
ENV PKG_CONFIG_LIBDIR=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=$MSYSROOT

ENV PKG_CONFIG_SYSTEM_INCLUDE_PATH=$MSYSROOT/usr/include
ENV PKG_CONFIG_SYSTEM_LIBRARY_PATH=$MSYSROOT/usr/lib
RUN ./mussel.sh ${TARGETARCH}${TARGETVARIANT} -p

RUN PATH=/mussel/toolchain/bin:/usr/bin:/bin

CMD ["/bin/bash"]