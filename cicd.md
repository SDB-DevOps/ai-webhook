你是一个专业的 Kubernetes CI/CD 自动化 Agent。
请帮我执行以下代码仓库合并、构建、镜像推送、集群部署验证与异常排错全流程任务：

【任务参数】
- 代码仓库地址 (repo-url): https://github.com/SDB-DevOps/ai-webhook.git
- 目标镜像 Tag (destination-image): digo66/kagent-app:latest

【请按顺序执行以下 5 个步骤】：

Step 0: 合并代码
  - 合并指定代码仓库 (https://github.com/SDB-DevOps/ai-webhook.git) 的 feature 分支到 dev 分支。
  - 如果合并失败，请自动在 GitHub 仓库中创建修复分支 (fix branch)、提交修改并创建 Pull Request。
  
Step 1: 代码拉取与检查
  - 如果Step 0成功，请拉取指定代码仓库 (https://github.com/SDB-DevOps/ai-webhook.git) 的 dev 分支到工作目录。
  - 检查代码仓库结构，确认 Dockerfile (Dockerfile) 存在并有效。

Step 2: 容器镜像构建与推送
  - 检查代码仓库中 Helm 的 Chart.yaml 文件，读取并提取 appVersion: 字段的值作为镜像的版本号 (Tag)。
  - 将目标镜像的 tag 版本部分更新为提取到的 appVersion（例如原镜像若为 digo66/kagent-app:latest，提取到 appVersion 为 0.1.2，则最终构建与推送的镜像为 digo66/kagent-app:0.1.2；若未找到 Chart.yaml 或未声明 appVersion，则继续使用原 Tag）。
  - 使用指定的 Dockerfile (Dockerfile) 和上下文 (.) 构建容器镜像。
  - 请将构建好的镜像推送至目标仓库。

Step 3: 构建与推送异常诊断与自动修复 (CI Failure Remediation)
  - 如果前面 Step 1 或 Step 2 遇到任何错误或构建/推送失败：
    1. 深入分析详细错误日志，找出根本原因 (Root Cause)。
    2. 给出具体的代码或配置修复建议。
    3. 请自动在 GitHub 仓库中创建修复分支 (fix branch)、提交修改并创建 Pull Request。

Step 4: 集群部署验证与运行时健康检查 (Deployment Verification & Health Check)
  - 若前面 CI 步骤均执行成功且无报错，请验证新镜像在 Kubernetes 集群中的部署与运行状态：
    【GitOps 规范约束】：本环境由 ArgoCD 严格按照 GitOps 声明式管理。在验证排错过程中仅允许进行只读状态观察与日志收集（如 kubectl get, describe, logs, rollout status 等），严禁执行任何命令式修改集群资源的操作（如禁止执行 kubectl rollout restart, edit, patch, set image 等命令式干预）。
    1. 检查新构建的容器镜像是否已正确同步并部署到 Kubernetes 集群中（查找匹配该镜像或应用的工作负载 Deployment / StatefulSet / Pod）。
    2. 状态判定与等待就绪：
       - 在镜像刚推送完成初期，Pod 可能会短暂出现 ErrImagePull 或 ImagePullBackOff，属于正常拉取延迟，Kubernetes 与 ArgoCD 会自动重试并等待镜像就绪，请保持只读观察。
       - 使用 kubectl rollout status deployment/[应用名称] --timeout=120s 等待确认部署完成。
       - 【正常就绪判定过滤】：若新镜像拉取成功且 Pod 处于 1/1 Running / Ready 状态、探针检查通过，则判定该部署状态为【健康正常 (HEALTHY)】。对于镜像推送完成前的瞬时拉取延迟，严禁将其作为故障进行长篇排错报警，也不要触发 PR 修复流程。
    3. 真正的运行时异常排错与自动修复：
       - 仅当 Pod 发生持续性、无法自愈的严重故障（例如持续 CrashLoopBackOff、启动 OOMKilled、代码抛异常退出、探针持续失败等）：
         a. 采集并分析容器的详细事件 (kubectl describe) 与运行日志 (kubectl logs)，精准定位根本原因 (Root Cause)。
         b. 给出清晰的问题诊断分析与可落地的修复建议。
         c. 若问题可以通过修改代码或配置（例如应用程序源码、Dockerfile、Helm values / 模板配置等）来修复，请自动在 GitHub 仓库中以当前出问题的分支为基础，创建修复分支 (fix branch)、提交代码修改并创建 Pull Request。

【汇报输出规范】：
请一步一步执行并详细汇报每个步骤的执行进展。
在汇报的最末尾，请务必输出规范的 Markdown 卡片式【📌 流水线执行摘要 (Pipeline Summary)】，格式示例如下：
================================================================================
### 📌 流水线执行摘要 (Pipeline Summary)
- **代码仓库**: https://github.com/SDB-DevOps/ai-webhook.git (分支: dev)
- **目标镜像**: [实际推送的镜像名称与最终版本Tag]
- **CI 阶段结果**: ✅ 成功 / ❌ 失败 ([简要说明])
- **CD 阶段结果**: ✅ 成功 (就绪状态) / ❌ 失败 ([简要说明])
- **自动修复状态**: 无需修复 / 已创建修复PR: [PR链接或分支名]
================================================================================