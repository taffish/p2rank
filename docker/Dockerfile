FROM debian:12-slim AS fpocket-builder

ARG FPOCKET_VERSION=4.2.3
ARG FPOCKET_SHA256=62b3da6490eeab0db488f0182150d340de2be0be23f4fd1def9d5846ce724ede
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    for attempt in 1 2 3 4 5; do \
        if apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
            ca-certificates \
            curl \
            gcc \
            g++ \
            libc6-dev \
            libnetcdf-dev \
            make; then \
            break; \
        fi; \
        if [ "$attempt" = 5 ]; then exit 1; fi; \
        apt-get -o Acquire::Retries=5 update; \
        sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/fpocket-build

RUN set -eux; \
    curl -fsSL -o fpocket.tar.gz "https://github.com/Discngine/fpocket/archive/refs/tags/${FPOCKET_VERSION}.tar.gz"; \
    echo "${FPOCKET_SHA256}  fpocket.tar.gz" | sha256sum -c -; \
    mkdir src; \
    tar -xzf fpocket.tar.gz -C src --strip-components=1

WORKDIR /tmp/fpocket-build/src

RUN set -eux; \
    make ARCH=LINUXAMD64 fpocket; \
    mkdir -p /opt/fpocket/bin /opt/fpocket/share/doc/fpocket /opt/fpocket/share/licenses/fpocket; \
    cp bin/fpocket /opt/fpocket/bin/fpocket; \
    cp README.md /opt/fpocket/share/doc/fpocket/README.md; \
    cp LICENSE /opt/fpocket/share/licenses/fpocket/LICENSE; \
    cp QHULL_COPYING.txt /opt/fpocket/share/licenses/fpocket/QHULL_COPYING.txt; \
    { \
        echo "fpocket ${FPOCKET_VERSION}"; \
        echo "source=https://github.com/Discngine/fpocket/archive/refs/tags/${FPOCKET_VERSION}.tar.gz"; \
        echo "sha256=${FPOCKET_SHA256}"; \
        echo "upstream_commit=4bb0d8447f62fee77e2c3c29f54b5fcaf5e2c066"; \
        echo "build_arch=LINUXAMD64"; \
    } > /opt/fpocket/share/doc/fpocket/source.txt; \
    chmod -R a+rX /opt/fpocket

FROM debian:12-slim AS p2rank-fetcher

ARG P2RANK_VERSION=2.5.1
ARG P2RANK_SHA256=d243f2d9036ac053fefb9407b5fe1c85f4fe077c519fd975ac585e995feab274
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    for attempt in 1 2 3 4 5; do \
        if apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
            ca-certificates \
            curl \
            tar \
            unzip; then \
            break; \
        fi; \
        if [ "$attempt" = 5 ]; then exit 1; fi; \
        apt-get -o Acquire::Retries=5 update; \
        sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/p2rank-fetch

RUN set -eux; \
    curl -fsSL -o p2rank.tar.gz "https://github.com/rdk/p2rank/releases/download/${P2RANK_VERSION}/p2rank_${P2RANK_VERSION}.tar.gz"; \
    echo "${P2RANK_SHA256}  p2rank.tar.gz" | sha256sum -c -; \
    mkdir -p /opt/p2rank; \
    tar -xzf p2rank.tar.gz -C /opt/p2rank --strip-components=1; \
    chmod 0755 /opt/p2rank/prank; \
    mkdir -p /opt/p2rank/cache; \
    cd /opt/p2rank/cache; \
    unzip -q /opt/p2rank/bin/lib/biojava-structure-7.2.2-rdk.1.jar 'chemcomp/*.cif.gz'; \
    { \
        echo "P2Rank ${P2RANK_VERSION}"; \
        echo "source=https://github.com/rdk/p2rank/releases/download/${P2RANK_VERSION}/p2rank_${P2RANK_VERSION}.tar.gz"; \
        echo "sha256=${P2RANK_SHA256}"; \
        echo "upstream_commit=9808a7723be9a94e2ffc21ab5f724cb6ae4ba01e"; \
        echo "java=17-24 supported by upstream; packaged runtime uses OpenJDK 17"; \
        echo "chemcomp_cache=56 reduced definitions extracted from bundled BioJava"; \
        echo "runtime_write_map=launcher seeds a writable per-run cache under /tmp"; \
        echo "bundled_helper=fpocket 4.2.3 for prank fpocket-rescore"; \
    } > /opt/p2rank/source.txt; \
    chmod -R a+rX /opt/p2rank

FROM debian:12-slim

ARG P2RANK_VERSION=2.5.1
ARG P2RANK_SHA256=d243f2d9036ac053fefb9407b5fe1c85f4fe077c519fd975ac585e995feab274
ARG FPOCKET_VERSION=4.2.3
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get -o Acquire::Retries=5 update; \
    for attempt in 1 2 3 4 5; do \
        if apt-get -o Acquire::Retries=5 install -y --no-install-recommends \
            bash \
            ca-certificates \
            coreutils \
            grep \
            libc-bin \
            libnetcdf19 \
            libstdc++6 \
            openjdk-17-jre-headless \
            sed; then \
            break; \
        fi; \
        if [ "$attempt" = 5 ]; then exit 1; fi; \
        apt-get -o Acquire::Retries=5 update; \
        sleep 5; \
    done; \
    rm -rf /var/lib/apt/lists/*

COPY --from=p2rank-fetcher /opt/p2rank /opt/p2rank
COPY --from=fpocket-builder /opt/fpocket /opt/fpocket
COPY --from=fpocket-builder /opt/fpocket/bin/fpocket /usr/local/bin/fpocket
COPY docker/prank-wrapper.sh /usr/local/bin/prank
COPY docker/p2rank-smoke.sh /usr/local/bin/taffish-p2rank-smoke

RUN set -eux; \
    chmod 0755 /usr/local/bin/prank /usr/local/bin/fpocket /usr/local/bin/taffish-p2rank-smoke

WORKDIR /root

ENV JAVA_OPTS=-Djava.awt.headless=true
ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=p2rank

RUN set -eux; \
    for cmd in prank java fpocket bash grep sed ldd taffish-p2rank-smoke; do \
        command -v "$cmd" >/dev/null; \
    done; \
    grep -Fx "P2Rank ${P2RANK_VERSION}" /opt/p2rank/source.txt >/dev/null; \
    grep -F "sha256=${P2RANK_SHA256}" /opt/p2rank/source.txt >/dev/null; \
    grep -Fx "fpocket ${FPOCKET_VERSION}" /opt/fpocket/share/doc/fpocket/source.txt >/dev/null; \
    test -s /opt/p2rank/bin/p2rank.jar; \
    test -s /opt/p2rank/models/default/model.zst; \
    test -s /opt/p2rank/models/default_rescore/model.zst; \
    test -s /opt/p2rank/config/default.groovy; \
    test -s /opt/p2rank/cache/chemcomp/PHE.cif.gz; \
    prank -v 2>&1 | grep -F "P2Rank ${P2RANK_VERSION}" >/dev/null; \
    { prank help 2>&1 || true; } | grep -F "predict pockets" >/dev/null; \
    { fpocket 2>&1 || true; } | grep -F "fpocket" >/dev/null; \
    taffish-p2rank-smoke predict; \
    taffish-p2rank-smoke fpocket-rescore; \
    ldd "$(command -v fpocket)" > /tmp/p2rank-fpocket-ldd.txt; \
    if grep -F "not found" /tmp/p2rank-fpocket-ldd.txt; then exit 1; fi; \
    rm -f /tmp/p2rank-fpocket-ldd.txt
