# Reusable Linux env for `make test-system` (macOS hosts, glibc for legacy release binaries, Foundry).
# Build once: `make test-system-docker-build`
# Run tests:  `make test-system-docker-reuse`
#
# Base must ship glibc >= legacy tarball needs (see root Makefile comment near test-system-docker).

FROM golang:1.25-trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -qq && \
	apt-get install -y --no-install-recommends \
		build-essential \
		git \
		make \
		curl \
		ca-certificates \
		jq \
		tar \
		xz-utils \
		python3 \
	&& rm -rf /var/lib/apt/lists/*

# Foundry (forge) — required for tests/systemtests/Counter
RUN curl -fsSL https://foundry.paradigm.xyz | bash && \
	bash -c 'export PATH="/root/.foundry/bin:$PATH" && foundryup'

ENV PATH="/root/.foundry/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

WORKDIR /workspace
