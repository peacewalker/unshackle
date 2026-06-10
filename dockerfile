FROM python:3.12-slim-bookworm

ARG SHAKA_VERSION=2.6.1
ARG DOVI_TOOL_VERSION=2.1.3

ENV PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    PATH="/root/.local/bin:/opt/bento4/bin:/usr/local/bin:${PATH}"

WORKDIR /opt/unshackle

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
    ffmpeg \
    mkvtoolnix \
    mediainfo \
    nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# shaka-packager: ARM64 下不一定每个版本都有官方二进制。
# 这里先尝试使用 apt/源码外的通用安装方式；如果失败，建议改成自己维护的二进制来源。
RUN case "$(uname -m)" in \
      x86_64) \
        curl -L "https://github.com/shaka-project/shaka-packager/releases/download/v${SHAKA_VERSION}/packager-linux-x64" \
          -o /usr/local/bin/packager && chmod +x /usr/local/bin/packager ;; \
      aarch64) \
        echo "ARM64 detected: please provide ARM64 shaka-packager binary or build it separately." ;; \
      *) \
        echo "Unsupported arch: $(uname -m)" && exit 1 ;; \
    esac

# Bento4: 官方预编译包多为 x86_64，ARM64 建议单独构建或换成可用来源。
# 若只构建镜像框架，可以先不安装 Bento4。
RUN case "$(uname -m)" in \
      x86_64) \
        curl -L "https://www.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip" \
          -o /tmp/bento4.zip \
        && unzip /tmp/bento4.zip -d /opt \
        && mv /opt/Bento4-SDK-* /opt/bento4 \
        && rm /tmp/bento4.zip ;; \
      aarch64) \
        echo "ARM64 detected: Bento4 mp4decrypt is not installed in this Dockerfile." ;; \
    esac

# dovi_tool 通常有多架构 release，但具体文件名可能随版本变化。
RUN case "$(uname -m)" in \
      x86_64) DOVI_ARCH="x86_64-unknown-linux-musl" ;; \
      aarch64) DOVI_ARCH="aarch64-unknown-linux-musl" ;; \
      *) echo "Unsupported arch: $(uname -m)" && exit 1 ;; \
    esac \
    && curl -L "https://github.com/quietvoid/dovi_tool/releases/download/${DOVI_TOOL_VERSION}/dovi_tool-${DOVI_TOOL_VERSION}-${DOVI_ARCH}.tar.gz" \
      -o /tmp/dovi_tool.tar.gz \
    && tar -xzf /tmp/dovi_tool.tar.gz -C /usr/local/bin dovi_tool \
    && chmod +x /usr/local/bin/dovi_tool \
    && rm /tmp/dovi_tool.tar.gz

COPY . .

RUN uv sync --no-dev

RUN mkdir -p /config /downloads /temp /logs /cookies /services /wvds /prds

ENV UNSHACKLE_CONFIG_DIR=/config

VOLUME ["/config", "/downloads", "/temp", "/logs", "/cookies", "/services", "/wvds", "/prds"]

ENTRYPOINT ["uv", "run", "unshackle"]
CMD ["--help"]
