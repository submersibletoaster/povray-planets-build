FROM ubuntu:xenial as build-deps

ENV COMPILED_BY="Andrew Bramble <bramble.andrew@gmail.com>"


# Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  bzip2 \
  cpanminus \
  g++ \
  git \
  make \
  wget

# Download and verify tarballs
ENV MEGAPOV_TARBALL="http://megapov.inetart.net/packages/unix/megapov-1.2.1-linux-amd64.tar.bz2"
ENV POVRAY_TARBALL="http://www.povray.org/redirect/www.povray.org/ftp/pub/povray/Old-Versions/Official-3.62/Unix/povray-3.6.tar.bz2"
COPY ./CHECKSUMS /
WORKDIR /tmp
RUN wget ${MEGAPOV_TARBALL}
RUN wget ${POVRAY_TARBALL}
RUN chdir /tmp && shasum -a 256 -c /CHECKSUMS


# Build povray
RUN chdir /tmp \
  && tar xjf /tmp/$(basename ${POVRAY_TARBALL}) \
  && cd povray-3.6.1 \
  && ./configure --disable-io-restrictions COMPILED_BY="${COMPILED_BY}" \
  && make check \
  && make install \
  && rm -rf /tmp/$(basename ${POVRAY_TARBALL})

# Install megapov (goes to /usr/local)
RUN chdir /tmp \
  && tar xjf /tmp/$(basename ${MEGAPOV_TARBALL}) \
  && script -c './megapov-1.2.1/install' < /dev/null \
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
