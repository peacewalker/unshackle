FROM python:3.12-slim-bookworm

ARG DOVI_TOOL_VERSION=2.1.3

ENV PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    PATH="/root/.local/bin:/usr/local/bin:${PATH}"

WORKDIR /opt/unshackle

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    xz-utils \
    ffmpeg \
    mkvtoolnix \
    mediainfo \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

RUN case "$(uname -m)" in \
      x86_64) DOVI_ARCH="x86_64-unknown-linux-musl" ;; \
      aarch64) DOVI_ARCH="aarch64-unknown-linux-musl" ;; \
      *) echo "Unsupported arch: $(uname -m)" && exit 1 ;; \
    esac \
    && curl -fL "https://github.com/quietvoid/dovi_tool/releases/download/${DOVI_TOOL_VERSION}/dovi_tool-${DOVI_TOOL_VERSION}-${DOVI_ARCH}.tar.gz" \
      -o /tmp/dovi_tool.tar.gz \
    && mkdir -p /tmp/dovi_tool_extract \
    && tar -xzf /tmp/dovi_tool.tar.gz -C /tmp/dovi_tool_extract \
    && find /tmp/dovi_tool_extract -type f -name "dovi_tool" -exec cp {} /usr/local/bin/dovi_tool \; \
    && chmod +x /usr/local/bin/dovi_tool \
    && dovi_tool --version \
    && rm -rf /tmp/dovi_tool.tar.gz /tmp/dovi_tool_extract

COPY . .

RUN uv sync --no-dev

RUN mkdir -p /config /downloads /temp /logs /cookies /services /wvds /prds

ENV UNSHACKLE_CONFIG_DIR=/config

VOLUME ["/config", "/downloads", "/temp", "/logs", "/cookies", "/services", "/wvds", "/prds"]

ENTRYPOINT ["uv", "run", "unshackle"]
CMD ["--help"]
