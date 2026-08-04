#!/usr/bin/env sh
# ServersEye 被控端自动安装脚本：从指定的 Worker 下载被控端并注册为 systemd 服务。
set -eu

controller="${SERVERSEYE_CONTROLLER:-}"
enroll_token="${SERVERSEYE_ENROLL_TOKEN:-}"
agent_name="${SERVERSEYE_AGENT_NAME:-}"
install_dir="${SERVERSEYE_INSTALL_DIR:-/opt/serverseye}"

usage() {
  cat <<'EOF'
用法：
  sh install-agent.sh --controller https://your-worker.workers.dev --token YOUR_ENROLL_TOKEN [--name NAME]

也可以使用环境变量 SERVERSEYE_CONTROLLER、SERVERSEYE_ENROLL_TOKEN、
SERVERSEYE_AGENT_NAME 与 SERVERSEYE_INSTALL_DIR。
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --controller) controller="${2:?--controller 需要一个地址}"; shift 2 ;;
    --token) enroll_token="${2:?--token 需要一个令牌}"; shift 2 ;;
    --name) agent_name="${2:?--name 需要一个名称}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "未知参数：$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$controller" in
  https://*) ;;
  *) echo "--controller 必须是 HTTPS Worker 地址" >&2; exit 2 ;;
esac
[ -n "$enroll_token" ] || { echo "请通过 --token 或 SERVERSEYE_ENROLL_TOKEN 提供注册令牌" >&2; exit 2; }

for command in curl sudo; do
  command -v "$command" >/dev/null 2>&1 || { echo "缺少命令：$command" >&2; exit 1; }
done

controller="${controller%/}"
agent_path="$install_dir/serverseye-agent.sh"
service_name="serverseye.service"

sudo mkdir -p "$install_dir" /etc/serverseye
curl --fail --show-error --silent --location "$controller/agent.sh" | sudo tee "$agent_path" >/dev/null
sudo chmod 755 "$agent_path"

if [ -n "$agent_name" ]; then
  sudo "$agent_path" register --token "$enroll_token" --name "$agent_name"
else
  sudo "$agent_path" register --token "$enroll_token"
fi

if command -v systemctl >/dev/null 2>&1; then
  sudo tee "/etc/systemd/system/$service_name" >/dev/null <<EOF
[Unit]
Description=ServersEye monitoring agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$agent_path run
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable --now "$service_name"
  echo "ServersEye 已安装并启动：$service_name"
else
  echo "已安装。请手动运行：sudo $agent_path run"
fi
