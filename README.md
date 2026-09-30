# 极简 Python Web 应用 Demo

本项目提供了一个基于 Python 的极简 Web 服务示例。

## 📦 依赖安装（使用清华镜像源）

本项目已在 `pyproject.toml` 中配置清华源镜像 (`https://pypi.tuna.tsinghua.edu.cn/simple`)：

### 使用 `uv` 同步依赖

```bash
uv sync
```

### 使用 `pip` 安装依赖

如果直接使用 `pip` 手动安装：

```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

或增加新的依赖包：

```bash
uv add fastapi uvicorn --index-url https://pypi.tuna.tsinghua.edu.cn/simple
```

---

## 🚀 快速运行

### 方式 1：使用 `uv` 运行（推荐）

```bash
uv run python main.py
```

### 方式 2：使用虚拟环境 Python 运行

```bash
./.venv/bin/python main.py
```

启动后访问：
- **Web 首页**: [http://127.0.0.1:8000](http://127.0.0.1:8000)
- **JSON API 接口**: [http://127.0.0.1:8000/api/hello](http://127.0.0.1:8000/api/hello)
- **动态 Greet 接口**: [http://127.0.0.1:8000/api/greet/Cline](http://127.0.0.1:8000/api/greet/Cline)
- **交互式 API 文档 (Swagger UI)**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

---

## 💡 代码架构说明

当前默认使用 **FastAPI**，代码简洁且原生支持数据校验与 Swagger API 自动生成。

### 1. FastAPI 版本 (`main.py`)

```python
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import uvicorn

app = FastAPI(title="极简 Python Web 应用")

@app.get("/", response_class=HTMLResponse)
def read_root():
    return "<h1>Hello World!</h1>"

@app.get("/api/hello")
def api_hello():
    return {"code": 200, "message": "Hello, World!"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
```

---

### 2. 补充：Flask 版本 (经典轻量)

如果你偏好 **Flask** 框架：

```python
from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return "<h1>Hello, Flask!</h1>"

@app.route("/api/hello")
def api_hello():
    return jsonify({"code": 200, "message": "Hello from Flask!"})

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=True)
```

---

### 3. 补充：Python 内置标准库版本 (零依赖)

无需安装任何第三方库，纯 Python 内置 `http.server` 即可实现：

```python
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class SimpleHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write("<h1>Hello World (标准库版本)</h1>".encode("utf-8"))
        elif self.path == "/api/hello":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"message": "Hello World"}).encode("utf-8"))

if __name__ == "__main__":
    server = HTTPServer(("127.0.0.1", 8000), SimpleHandler)
    print("Server running on http://127.0.0.1:8000")
    server.serve_forever()
```
---

## 🐳 Docker 打包与 K3s 集群部署

项目已包含完整 Container & Kubernetes (K3s) 配置文件：
- `Dockerfile` (基于 `python:3.13-slim`，构建时自动配置清华源)
- `.dockerignore`
- `k8s/deployment.yaml` (定义 2 个 Pod 副本、健康检查与资源限制)
- `k8s/service.yaml` (ClusterIP 服务)
- `k8s/ingress.yaml` (基于 Traefik 的路由配置)
- `deploy.sh` (一键部署脚本)

### 1. 手动构建与导入 K3s

```bash
# 1) 构建 Docker 镜像
docker build -t demo-web:latest .

# 2) 将本地构建的镜像导入 K3s 内置 containerd
sudo k3s ctr images import <(docker save demo-web:latest)
# 或使用 ctr:
# docker save demo-web:latest | sudo ctr -n k8s.io images import -

# 3) 部署到 K3s 集群
kubectl apply -f k8s/

# 4) 查看部署状态
kubectl get pods -l app=demo-web
kubectl get svc demo-web-service
```

### 2. 一键自动构建部署

执行项目根目录下的自动化脚本：

```bash
./deploy.sh
```

