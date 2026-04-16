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

这意味着前端镜像更适合和反向代理一起部署，由反向代理把：

- `/api/*`
- `/auth/*`
- `/ws`

转发到 Go 后端。

## 本地一键部署

仓库根目录提供：

- `docker-compose.yml`
- `Caddyfile`
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

默认访问地址：

- `http://localhost:3000`

## 本地 compose 结构

`docker-compose.yml` 会启动：

- `postgres`
- `backend`
- `frontend`
- `gateway`（Caddy）

其中：

- 浏览器只访问 `gateway`
- `gateway` 把 `/api`、`/auth`、`/ws` 转发到后端
- 其余页面请求转发到前端
