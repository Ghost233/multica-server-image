# multica-server-image

用于打包 Multica 的 release 版本镜像。

当前仓库只跟踪 **upstream release tag**，不再跟踪 `main` 的日常版本。

## 仓库内容

这个仓库会产出两个镜像：

- 后端镜像：`ghcr.io/ghost233/multica-server-image/backend`
- 前端镜像：`ghcr.io/ghost233/multica-server-image/frontend`

两者都只按 upstream release tag 构建，例如：

- `ghcr.io/ghost233/multica-server-image/backend:v0.2.0`
- `ghcr.io/ghost233/multica-server-image/frontend:v0.2.0`

同时也会更新：

- `ghcr.io/ghost233/multica-server-image/backend:latest`
- `ghcr.io/ghost233/multica-server-image/frontend:latest`

## 构建方式

### 手动构建

使用 `Build Release Images` workflow，输入 upstream release tag，例如：

- `v0.2.0`

### 自动同步

`Sync Upstream Release Images` workflow 每天 `UTC 00:00` 检查上游最新 release tag。

如果发现：

- 仓库记录的 release tag 发生变化，或
- backend/frontend 对应镜像不存在

就会自动重新构建并推送镜像。

当前同步状态记录在：

- `.state/release-tag`

## 前端镜像说明

前端镜像会在构建时把 `apps/web` 调整为更适合自托管的形态：

- 启用 Next.js standalone 输出
- 默认使用同源 API
- 默认按当前站点域名推导 WebSocket 地址 `/ws`

这意味着前端镜像更适合和外部反向代理一起部署，由外部 `nginx` 或其他代理把：

- `/api/*`
- `/auth/*`
- `/ws`

转发到 Go 后端。

## 本地一键部署

## 一键安装脚本

如果你想像常见自托管应用一样直接执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Ghost233/multica-server-image/main/install.sh | sh
```

脚本会自动：

1. 下载 `docker-compose.yml`
2. 下载 `.env.example`
3. 生成本地 `.env`
4. 自动生成随机 `JWT_SECRET`
5. 执行 `docker compose up -d`

默认会把文件直接安装到当前执行目录。

你也可以在执行前通过环境变量覆盖默认行为，例如：

```bash
INSTALL_DIR=/opt/multica MULTICA_TAG=v0.2.0 FRONTEND_PORT=80 BACKEND_PORT=8080 \
  curl -fsSL https://raw.githubusercontent.com/Ghost233/multica-server-image/main/install.sh | sh
```

可用环境变量：

- `INSTALL_DIR`
- `FORCE=1`（允许覆盖已有文件）
- `MULTICA_TAG`
- `POSTGRES_DB`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `BACKEND_PORT`
- `FRONTEND_PORT`

仓库根目录提供：

- `docker-compose.yml`
- `.env.example`

使用步骤：

1. 复制环境文件：

```bash
cp .env.example .env
```

2. 至少修改：

- `JWT_SECRET`
- `MULTICA_TAG`（可选，默认 `latest`）

3. 启动：

```bash
docker compose up -d
```

默认端口：

- frontend: `http://localhost:3000`
- backend: `http://localhost:8080`

默认数据目录：

- `./data/postgres`

## 本地 compose 结构

`docker-compose.yml` 会启动：

- `postgres`
- `backend`
- `frontend`

其中 PostgreSQL 数据使用本地目录持久化：

- `./data/postgres` -> `/var/lib/postgresql/data`

这个 compose **不再内置 gateway**。

也就是说：

- 如果你本地直接访问前端，可以访问 `FRONTEND_PORT`
- 如果你在线上已经有外部 `nginx`，就由外部 `nginx` 自己把：
  - 页面请求转发到 frontend
  - `/api`、`/auth`、`/ws` 转发到 backend

## 外部反向代理建议

如果你使用外部 `nginx`，推荐的转发规则是：

- `/api/` -> backend:8080
- `/auth/` -> backend:8080
- `/ws` -> backend:8080
- 其他路径 -> frontend:3000

仓库内提供了一个可直接参考的示例文件：

- `nginx.conf.example`
