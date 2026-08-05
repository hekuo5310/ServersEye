# ServersEye

[![Deploy to Cloudflare](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https%3A%2F%2Fgithub.com%2Fhekuo5310%2FServersEye)

运行在 Cloudflare Workers 上的轻量服务器探针主控，配套无语言运行时依赖的 POSIX `sh` 被控端。被控端由 Worker 直接生成并下载，因此主控地址会自动预设为当前 Worker 域名。

## 功能

- Worker + D1 保存服务器状态，KV 仅缓存服务器列表 30 秒，无需独立主控服务器。
- 注册采用一次性部署时设置的 `ENROLL_TOKEN`；每台被控端再获得独立令牌，Worker 只保存其 SHA-256 哈希。
- 上报主机名、系统、负载、CPU、内存、磁盘、网络收发和运行时长。
- 管理接口由独立 `ADMIN_TOKEN` 保护。

## 部署主控

1. 安装依赖：`npm install`
2. 创建 D1：`npx wrangler d1 create serverseye`；创建 KV 缓存：`npx wrangler kv namespace create CACHE`。
3. 把输出的 D1 `database_id` 和 KV namespace id 填入 `wrangler.toml`。
4. 设置两个高强度随机密钥：

   ```sh
   npm run secret:enroll
   npm run secret:admin
   ```

5. 部署：`npm run deploy`。该命令会先执行 `migrations/` 中的 D1 数据库迁移，再部署 Worker。

通过 README 顶部的一键部署按钮时，Cloudflare 会根据 `wrangler.toml` 自动创建并绑定 D1 与 KV；D1 迁移由部署脚本执行。

## 安装被控端

目标服务器需要 Linux 自带的 `sh`、`/proc`、`curl` 和 `sudo`。把 `<worker-url>` 替换为部署后的地址：

```sh
export SERVERSEYE_ENROLL_TOKEN='你的 ENROLL_TOKEN'
curl -fsSL <worker-url>/install.sh | sh
sudo /opt/serverseye/serverseye-agent.sh run
```

`/install.sh` 从同一个 Worker 拉取 `/agent.sh`，这个文件中的主控地址已自动写成 Worker 实际域名。在支持 systemd 的 Linux 上，脚本会自动创建并启动 `serverseye.service`。

仓库也提供独立安装脚本，适合先下载到被控服务器后再执行：

```sh
curl -fsSLO https://raw.githubusercontent.com/hekuo5310/ServersEye/main/install-agent.sh
sh install-agent.sh --controller <worker-url> --token '你的 ENROLL_TOKEN' --name '服务器名称'
```

独立脚本同样从指定 Worker 的 `/agent.sh` 拉取被控端，不会把注册令牌写进下载地址或仓库。

## 查看所有服务器

```sh
curl -H 'Authorization: Bearer 你的 ADMIN_TOKEN' <worker-url>/api/agents
```

返回 JSON 中每台服务器的 `updated_at` 是最后心跳时间（Unix 毫秒）。请不要把任一令牌提交到 GitHub。

## 本地检查

```sh
npm install
npm run check
```
