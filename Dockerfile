# 使用官方轻量级 Python 3.13 镜像
FROM python:3.13-slim

# 创建非 root 运行用户与用户组 (解决 S6471)
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# 设置工作目录
WORKDIR /app

# 设置环境变量：阻止 Python 生成 .pyc 文件，确保日志即时输出
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 复制依赖定义文件
COPY requirements.txt .

# 仅安装二进制 Wheel，禁止执行源码构建脚本 (解决 S8541)
RUN pip install --no-cache-dir --only-binary :all: -r requirements.txt

# 显式复制应用源码，避免递归拷贝可能带入敏感数据 (解决 S6470)
COPY --chown=appuser:appgroup main.py .

# 切换为非 root 用户运行
USER appuser

# 暴露容器内部端口
EXPOSE 8000

# 启动 Uvicorn 服务（绑定 0.0.0.0 以允许容器外通信）
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
