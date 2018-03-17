FROM ubuntu:xenial

LABEL org.povray-planets.version "1.0"

LABEL maintainer="<Andrew Bramble> bramble.andrew@gmail.com"

VOLUME "/var/cache/apt"
VOLUME "/var/lib/apt"

ENV MEGAPOV_TARBALL="megapov-1.2.1-linux-amd64.tar.bz2"

# Dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  bzip2 \
  git \
  wget

COPY ./CHECKSUMS /

# Fetch - verify unpack and symlink megapov into /opt/megapov
RUN chdir /tmp \
    && wget http://megapov.inetart.net/packages/unix/${MEGAPOV_TARBALL} \
    && shasum -a 256 -c /CHECKSUMS \
    && chdir /opt \
    && tar xjf /tmp/${MEGAPOV_TARBALL} \
    && ln -s megapov-1.2.1 megapov \
    && rm -f /tmp/${MEGAPOV_TARBALL}


# dump the git repo (without .git) into /opt/povray-planets
COPY ./ /tmp/source
RUN chdir /tmp/source \
  && git checkout-index --prefix /opt/povray-planets/ -a \
  && rm -rf /tmp/source
