#!/usr/bin/env bash

set -e

IMAGE_NAME="demo-web:latest"

echo "📦 1. 正在使用 uv 导出最新的 requirements.txt..."
uv export --format requirements-txt -o requirements.txt

echo "🐳 2. 正在构建 Docker 镜像: ${IMAGE_NAME}..."
docker build -t ${IMAGE_NAME} .

echo "🚚 3. 导入镜像至 K3s 集群..."
if command -v k3s &> /dev/null; then
    sudo k3s ctr images import <(docker save ${IMAGE_NAME}) || echo "⚠️ 自动导入镜像失败，请根据实际环境导入镜像"
elif command -v ctr &> /dev/null; then
    docker save ${IMAGE_NAME} | sudo ctr -n k8s.io images import - || echo "⚠️ 自动导入镜像失败，请根据实际环境导入镜像"
else
    echo "💡 未检测到本地 k3s 命令，若使用远程 k3s 或 registry，请将镜像推送至镜像仓库。"
fi

echo "🚀 4. 部署应用至 Kubernetes (K3s)..."
kubectl apply -f k8s/

echo "✅ 5. 部署状态检查:"
kubectl get pods -l app=demo-web
kubectl get svc -l app=demo-web
kubectl get ingress
