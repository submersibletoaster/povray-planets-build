FROM ubuntu:xenial as build-deps

ENV COMPILED_BY="Andrew Bramble <bramble.andrew@gmail.com>"

ENV MEGAPOV_TARBALL="http://megapov.inetart.net/packages/unix/megapov-1.2.1-linux-amd64.tar.bz2"
ENV POVRAY_TARBALL="http://www.povray.org/redirect/www.povray.org/ftp/pub/povray/Old-Versions/Official-3.62/Unix/povray-3.6.tar.bz2"
# Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  bzip2 \
  cpanminus \
  g++ \
  git \
  make \
  wget

COPY ./CHECKSUMS /

# Build povray
RUN chdir /tmp \
  && wget $POVRAY_TARBALL \
  && grep povray /CHECKSUMS | shasum -a 256 -c \
  && chdir /tmp \
  && tar xjf /tmp/$(basename ${POVRAY_TARBALL}) \
  && cd povray-3.6.1 \
  && ./configure --disable-io-restrictions COMPILED_BY="${COMPILED_BY}" \
  && make check \
  && make install \
  && rm -rf /tmp/$(basename ${POVRAY_TARBALL}) \
  && rm -rf /tmp/povray-3.6.1

# Fetch - verify unpack and symlink megapov into /opt/megapov
RUN chdir /tmp \
  && wget ${MEGAPOV_TARBALL} \
  && grep megapov /CHECKSUMS | shasum -a 256 -c \
  && tar xjf /tmp/$(basename ${MEGAPOV_TARBALL}) \
  && ./megapov-1.2.1/install \
  && rm -f /tmp/$(basename ${MEGAPOV_TARBALL})

# Used for cpan Imager::File::PNG , breaks povray compilation if installed early
RUN apt-get install -y --no-install-recommends \
  libpng16-dev

# Add perl Dependencies
COPY ./cpanfile /
RUN chdir / \
  && cpanm --installdeps .




# dump the git repo (without .git) into /opt/povray-planets
FROM build-deps

LABEL org.povray-planets.version "1.0"
LABEL maintainer="<Andrew Bramble> bramble.andrew@gmail.com"

COPY ./ /tmp/source
RUN chdir /tmp/source \
  && git checkout-index --prefix /opt/povray-planets/ -a \
  && rm -rf /tmp/source
