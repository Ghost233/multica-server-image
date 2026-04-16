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

注意：如果你要通过环境变量覆盖安装参数，变量必须传给 `sh`，不能只传给前面的 `curl`。

脚本会自动：

1. 下载 `docker-compose.yml`
2. 下载 `.env.example`
3. 生成本地 `.env`
4. 自动生成随机 `JWT_SECRET`
5. 调用 `./start.sh` 启动容器

默认会把文件直接安装到当前执行目录。

你也可以在执行前通过环境变量覆盖默认行为，例如：

```bash
curl -fsSL https://raw.githubusercontent.com/Ghost233/multica-server-image/main/install.sh | \
  INSTALL_DIR=/opt/multica MULTICA_TAG=v0.2.0 FRONTEND_PORT=80 BACKEND_PORT=8080 sh
```

或者先下载脚本再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/Ghost233/multica-server-image/main/install.sh -o install.sh
chmod +x install.sh
INSTALL_DIR=/opt/multica MULTICA_TAG=v0.2.0 FRONTEND_PORT=80 BACKEND_PORT=8080 ./install.sh
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
- `REMOTE_API_URL`

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
./start.sh
```

其他常用命令：

```bash
./status.sh
./restart.sh
./stop.sh
./update.sh
```

强制拉取最新镜像并重建容器：

```bash
./update.sh
```

如果你只想更新某个服务，例如只更新 frontend：

```bash
./update.sh frontend
```

等价的底层命令是：

```bash
docker compose --env-file .env pull frontend backend
docker compose --env-file .env up -d --force-recreate frontend backend
```

默认端口：

- frontend: `http://localhost:3000`
- backend: `http://localhost:8080`

前端容器默认通过 `REMOTE_API_URL=http://backend:8080` 把 `/api`、`/auth`、`/ws` 代理到 backend 容器。

## 配置说明

这套默认部署里有三类地址，不要混用：

- `REMOTE_API_URL`：给 frontend 容器里的 Next.js server / rewrite 使用，应该填写 **Docker 内部地址**，默认就是 `http://backend:8080`。
- `NEXT_PUBLIC_API_URL`：给浏览器端显式 API 基地址使用。默认同源部署下 **不需要配置**。
- `NEXT_PUBLIC_WS_URL`：给浏览器端显式 WebSocket 地址使用。默认同源部署下 **不需要配置**，前端会按当前页面域名自动推导 `/ws`。

例如：

- 页面地址：`https://multica.example.com`
- 前端会自动把 WebSocket 目标推导成：`wss://multica.example.com/ws`

所以在外部 `nginx` 已经把 `/api`、`/auth`、`/ws` 都代理到 backend 的前提下，通常只需要保留：

```env
REMOTE_API_URL=http://backend:8080
```

而不需要额外设置：

```env
NEXT_PUBLIC_API_URL=
NEXT_PUBLIC_WS_URL=
```

默认数据目录：

- `./data/postgres`
- `./data/uploads`

## 本地 compose 结构

`docker-compose.yml` 会启动：

- `postgres`
- `backend`
- `frontend`

其中本地数据目录会分别持久化：

- `./data/postgres` -> PostgreSQL 数据目录 `/var/lib/postgresql/data`
- `./data/uploads` -> backend 本地上传目录 `/app/data/uploads`

这个 compose **不再内置 gateway**。

也就是说：

- 如果你本地直接访问前端，可以访问 `FRONTEND_PORT`
- 如果你在线上已经有外部 `nginx`，就由外部 `nginx` 自己把：
  - 页面请求转发到 frontend
  - `/api`、`/auth`、`/ws` 转发到 backend

## 外部反向代理建议

如果你需要改内部前后端代理目标，可以在 `.env` 里覆盖 `REMOTE_API_URL`，默认值是 `http://backend:8080`。

如果你走同域部署，外部反向代理必须保证下面三条都能通到 backend：

- `/api/*`
- `/auth/*`
- `/ws`

如果 `/ws` 没有正确转发，登录后页面会因为实时连接失败而表现异常。

如果你使用外部 `nginx`，推荐的转发规则是：

- `/api/` -> backend:8080
- `/auth/` -> backend:8080
- `/ws` -> backend:8080
- 其他路径 -> frontend:3000

仓库内提供了一个可直接参考的示例文件：

- `nginx.conf.example`
