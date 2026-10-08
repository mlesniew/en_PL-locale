# Test image for install-en_PL.sh. Build from the repository root:
#   docker build -f tests/Dockerfile --build-arg BASE_IMAGE=fedora:latest .
ARG BASE_IMAGE=debian:stable-slim
FROM ${BASE_IMAGE}

# Each family needs localedef plus the glibc locale sources, python3 (strfmon
# checks), tzdata (Europe/Warsaw), sudo and useradd (non-root install test).
RUN set -eux; \
    if command -v apt-get >/dev/null; then \
        apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            locales python3 tzdata sudo; \
        # Desktop Ubuntu has language packs, which create supported.d; the
        # bare container image does not, and would take the locale.gen path.
        . /etc/os-release; \
        if [ "$ID" = ubuntu ]; then \
            apt-get install -y --no-install-recommends language-pack-en-base; \
        fi; \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v pacman >/dev/null; then \
        # The Arch image strips locale sources via NoExtract; reinstall glibc
        # without it so /usr/share/i18n/locales is complete.
        sed -i '/^NoExtract/d' /etc/pacman.conf; \
        pacman -Syu --noconfirm; \
        pacman -S --noconfirm glibc python tzdata sudo; \
        pacman -Scc --noconfirm; \
    elif command -v dnf >/dev/null; then \
        dnf install -y glibc-locale-source python3 tzdata sudo shadow-utils; \
        dnf clean all; \
    else \
        echo "unsupported base image" >&2; exit 1; \
    fi

WORKDIR /src
COPY install-en_PL.sh README.md ./
COPY tests/ tests/
CMD ["tests/run.sh"]
