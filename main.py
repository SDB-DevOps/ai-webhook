from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import uvicorn

app = FastAPI(
    title="极简 Python Web 应用",
    description="基于 FastAPI 开发的极简 Web 服务",
    version="1.0.0",
)


@app.get("/", response_class=HTMLResponse)
def read_root():
    return """
    <!DOCTYPE html>
    <html lang="zh-CN">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>极简 Python Web 应用</title>
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                color: #333;
            }
            .card {
                background: white;
                padding: 2.5rem;
                border-radius: 16px;
                box-shadow: 0 10px 25px rgba(0,0,0,0.2);
                max-width: 480px;
                width: 90%;
                text-align: center;
            }
            h1 { font-size: 1.8rem; color: #4a5568; margin-bottom: 1rem; }
            p { color: #718096; margin-bottom: 1.5rem; line-height: 1.6; }
            .btn-group { display: flex; gap: 10px; justify-content: center; }
            a.btn {
                display: inline-block;
                padding: 10px 20px;
                background: #667eea;
                color: white;
                text-decoration: none;
                border-radius: 8px;
                font-weight: 600;
                transition: background 0.2s;
            }
            a.btn:hover { background: #5a67d8; }
            a.btn-secondary { background: #edf2f7; color: #4a5568; }
            a.btn-secondary:hover { background: #e2e8f0; }
        </style>
    </head>
    <body>
        <div class="card">
            <h1>🚀 极简 Python Web 应用</h1>
            <p>欢迎！这是一个基于 <strong>FastAPI</strong> 构筑的轻量级 Web 服务。</p>
            <div class="btn-group">
                <a href="/api/hello" class="btn">测试 API 接口</a>
                <a href="/docs" class="btn btn-secondary" target="_blank">查看 API 文档</a>
            </div>
        </div>
    </body>
    </html>
    """


@app.get("/api/hello")
def api_hello():
    return {
        "code": 200,
        "message": "Hello, World! 欢迎使用极简 Python Web 服务！",
        "status": "success",
    }


@app.get("/api/greet/{name}")
def api_greet(name: str):
    return {"code": 200, "message": f"你好，{name}！", "user": name}


if __name__ == "__main__":
    print("🚀 服务正在启动: http://127.0.0.1:8000")
    print("📚 接口文档地址: http://127.0.0.1:8000/docs")
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)

