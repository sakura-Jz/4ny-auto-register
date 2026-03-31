# Stage 1: 构建前端
FROM node:20-bookworm-slim AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Stage 2: Python 后端 + 运行环境
FROM python:3.12-slim-bookworm

# 系统依赖：Chromium、Xvfb、x11vnc、noVNC
RUN sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list.d/debian.sources \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        chromium \
        chromium-driver \
        xvfb \
        x11vnc \
        novnc \
        websockify \
        curl \
        ca-certificates \
        fonts-liberation \
        libnss3 \
        libatk-bridge2.0-0 \
        libdrm2 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        libgbm1 \
        libxkbcommon0 \
        libasound2 \
        libpango-1.0-0 \
        libcairo2 \
        libgtk-3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 安装 Python 依赖
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

ENV PLAYWRIGHT_EXECUTABLE_PATH=/usr/bin/chromium

# 复制后端代码
COPY . .
# 不需要 .venv 和 frontend 源码
RUN rm -rf .venv frontend

# 复制前端构建产物
COPY --from=frontend-builder /app/static ./static

# 启动脚本
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN sed -i 's/\r$//' /docker-entrypoint.sh \
    && chmod +x /docker-entrypoint.sh

EXPOSE 8000 6080

ENTRYPOINT ["/docker-entrypoint.sh"]
