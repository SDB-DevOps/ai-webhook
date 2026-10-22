# 使用官方轻量级 Python 3.13 镜像
FROM python:3.13-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量：阻止 Python 生成 .pyc 文件，确保日志即时输出
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 复制依赖定义文件
COPY requirements.txt .

# 使用清华镜像源安装依赖，不留缓存
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用程序代码
COPY . /app

# 暴露容器内部端口
EXPOSE 8000

# 启动 Uvicorn 服务（绑定 0.0.0.0 以允许容器外通信）
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
