# Build stage for mussel toolchain
FROM debian:bullseye-slim as musl-toolchain

# Specify release variables
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}
ARG TARGETVARIANT
ENV TARGETVARIANT=${TARGETVARIANT}
ARG BUILDARCH
ARG BUILDVARIANT
ENV RLS_OS=linux
ENV RLS_LIB=gnu
ENV RLS_ARCH=x86_64
ENV PKG_CONFIG_PATH=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
ENV PKG_CONFIG_LIBDIR=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=$MSYSROOT
ENV PKG_CONFIG_SYSTEM_INCLUDE_PATH=$MSYSROOT/usr/include
ENV PKG_CONFIG_SYSTEM_LIBRARY_PATH=$MSYSROOT/usr/lib
ENV PATH=/mussel/toolchain/bin:/usr/bin:/bin

# determine architecture
RUN ARCHITECTURE=$(dpkg --print-architecture) \
    && if [ "${ARCHITECTURE}" = "amd64" ]; then RLS_ARCH=x86_64 ; fi \
    && if [ "${ARCHITECTURE}" = "arm64" ]; then RLS_ARCH=aarch64; fi \
    && if [ "${ARCHITECTURE}" = "armhf" ]; then RLS_ARCH=armhf && RLS_LIB=gnueabihf; fi \
    && if [ "${ARCHITECTURE}" = "i386" ]; then RLS_ARCH=i386; fi \
    && if [ "${RLS_ARCH}" = "" ]; then echo "Could not determine architecture" >&2; exit 1; fi \
    && echo ${RLS_ARCH}-${RLS_OS}-${RLS_LIB} >> ~/host.txt

ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN mkdir -p /mussel \
  && apt-get update -y \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  bash \
  bc \
  binutils \
  bison \
  build-essential \
  bzip2 \
  coreutils \
  ccache \
  diffutils \
  file \
  flex \
  findutils \
  gawk \
  git \
  grep \
  gzip \
  libarchive-dev \
  libarchive-tools \
  libc6 \
  libbison-dev \
  libzstd-dev \
  lzip \
  m4 \
  make \
  "musl:$(dpkg --print-architecture)" \
  perl \
  pv \
  rsync \
  sed \
  texinfo \
  wget \
  xz-utils \
  zstd

RUN ln -s /lib/$(cat ~/host.txt)/libc.so.6 /lib/libc.so.6

COPY /patches/ /mussel/patches/
COPY check.sh \
    mussel.sh /mussel/

WORKDIR /mussel

RUN ./check.sh

RUN ./mussel.sh ${TARGETARCH} -k -l -o -p

RUN rm -rf ./build ./sources

FROM debian:bullseye-slim AS final

# Specify release variables
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH}
ARG TARGETVARIANT
ENV TARGETVARIANT=${TARGETVARIANT}
ARG BUILDARCH
ARG BUILDVARIANT
ENV RLS_OS=linux
ENV RLS_LIB=gnu
ENV RLS_ARCH=x86_64
ENV PKG_CONFIG_PATH=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
ENV PKG_CONFIG_LIBDIR=$MSYSROOT/usr/lib/pkgconfig:$MSYSROOT/usr/share/pkgconfig
ENV PKG_CONFIG_SYSROOT_DIR=$MSYSROOT
ENV PKG_CONFIG_SYSTEM_INCLUDE_PATH=$MSYSROOT/usr/include
ENV PKG_CONFIG_SYSTEM_LIBRARY_PATH=$MSYSROOT/usr/lib
ENV PATH=/mussel/toolchain/bin:/usr/bin:/bin

RUN mkdir -p /mussel/

WORKDIR /mussel

COPY --from=musl-toolchain /mussel/toolchain/ /mussel/
COPY --from=musl-toolchain /mussel/sysroot/ /mussel/

CMD ["/bin/bash"]