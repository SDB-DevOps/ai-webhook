你是一个专业的 Kubernetes CI/CD 自动化 Agent。
请按顺序执行代码合并、代码扫描、镜像构建推送、集群部署验证与异常排错全流程：

【任务参数】
- 代码仓库地址 (repo-url): https://github.com/SDB-DevOps/ai-webhook.git
- 分支配置（支持对话中动态指定；若用户未指定则使用默认值）:
  - 源分支 (source-branch): `${SOURCE_BRANCH:-feature}`
  - 目标分支 (target-branch): `${TARGET_BRANCH:-dev}`
- 目标镜像: digo66/kagent-app (版本将由 Chart.yaml appVersion 动态决定)
- Kubernetes 部署: namespace: `default`, app-name: `ai-webhook`
- SonarCloud 配置:
  - Project Key: `SDB-DevOps_ai-webhook` | Organization: `sdb-devops` | Host: `https://sonarcloud.io`
  - 凭证: 环境变量 `SONAR_TOKEN`
- 镜像仓库推送凭据: 环境变量 `DOCKER_CONFIG` 或挂载 `/kaniko/.docker/config.json`（供 Kaniko 鉴权）

【执行步骤】：

Step 0: 合并代码与基线锚定
  - 记录合并前 `target-branch` 分支最新 SHA: `PRE_MERGE_SHA=$(git rev-parse HEAD)`，用于故障回滚基线。
  - 将 `source-branch` 分支合并到 `target-branch` 并推送至远程。
  - 若合并冲突，自动在 GitHub 创建修复分支并向 `source-branch` 分支提交 PR。

Step 1: 代码拉取与检查
  - 拉取 `target-branch` 分支最新代码，确认 Dockerfile 存在有效。

Step 2: SonarCloud 质量扫描与门禁检查
  - 运行扫描并同步等待质量门禁：
    ```bash
    sonar-scanner \
      -Dsonar.host.url=https://sonarcloud.io \
      -Dsonar.organization=sdb-devops \
      -Dsonar.projectKey=SDB-DevOps_ai-webhook \
      -Dsonar.branch.name="${TARGET_BRANCH:-dev}" \
      -Dsonar.sources=. \
      -Dsonar.sourceEncoding=UTF-8 \
      -Dsonar.exclusions="**/.venv/**,**/venv/**,**/__pycache__/**" \
      -Dsonar.token="${SONAR_TOKEN}" \
      -Dsonar.qualitygate.wait=true
    ```
  - 门禁检查与代码缺陷判定：
    - 若门禁判定为 `FAILED` 或扫描出中高危缺陷（如 Dockerfile 敏感文件拷贝、代码漏洞等）：
      深入分析缺陷根因，若能通过修改代码或配置文件修复，直接转入 Step 4 自动创建修复分支并向 `source-branch` 提 PR 修复。

Step 3: 使用 Kaniko 构建与推送容器镜像 (Helm appVersion 联动)
  - 读取 `k8s/Chart.yaml` 的 `appVersion`，将其作为镜像 Tag：`IMAGE_TAG=${APP_VERSION:-latest}`，目标镜像完整标识为 `digo66/kagent-app:${IMAGE_TAG}`。
  - 使用 Kaniko 执行器 (`gcr.io/kaniko-project/executor:latest` 或容器内 `/kaniko/executor`) 执行无守护进程镜像构建与推送：
    ```bash
    /kaniko/executor \
      --context=dir://. \
      --dockerfile=Dockerfile \
      --destination=docker.io/digo66/kagent-app:${IMAGE_TAG} \
      --cache=true
    ```
  - 【强阻断门禁】：
    - 检查 Kaniko 执行退出码。若镜像构建或推送失败（退出码非 0），必须在此步骤立即阻断并退出，严禁进入 Step 5，直接转入 Step 4 进行故障诊断与修复。
    - 确保 Git 仓库中声明的 Helm values / Chart.yaml 的版本与已成功推送的镜像严格一致，以供 ArgoCD 自动同步拉取。

Step 4: CI 阶段与代码质量异常诊断与自动修复
  - 若 Step 1~3 任意环节失败（包括 SonarCloud 发现可代码修复的缺陷/门禁不通过、Kaniko 镜像构建或推送失败等）：
    1. 深入分析日志或 SonarCloud Issue 详情，定位根本原因，给出修复建议。
    2. 在 GitHub 自动创建修复分支（分支名形如 `fix/sonar-[issue-type]` 或 `fix/ci-[failure-type]`）。
    3. 实施具体的代码修复（如修复代码 Bug、优化 Dockerfile 指令与补全 `.dockerignore`、修复 Helm 配置等）并提交变更。
    4. 向 `source-branch` 分支提交 Pull Request，并在 PR 描述中清晰说明问题原因与修复变更。

Step 5: 集群部署验证与运行时健康检查 (GitOps 规范)
  - 【只读约束】：ArgoCD 声明式托管，严禁命令式修改资源（禁止 edit/patch/restart/set image），仅允许只读观察。
  - 状态验证与就绪判定：
    - 执行 `kubectl rollout status deployment/ai-webhook -n default --timeout=120s` 等待部署。
    - 允许拉取初期短暂的 `ImagePullBackOff`（正常拉取延迟，严禁报障或提PR）；当 Pod 处于 1/1 Running / Ready 即判定为【HEALTHY】。
  - 严重故障自动修复与回滚（持续 CrashLoopBackOff/OOM/探针持续失败）：
    1. 收集 `kubectl describe` 与 `kubectl logs` 定位根因，向 `source-branch` 提修复 PR。
    2. 回滚 `target-branch` 分支与集群：
       - 优先 Revert: `git revert -m 1 <MERGE_COMMIT_SHA> -m "revert: rollback dev due to failure" && git push origin ${TARGET_BRANCH:-dev}`
       - 允许强推场景: `git reset --hard ${PRE_MERGE_SHA} && git push origin ${TARGET_BRANCH:-dev} --force`
       - 推送后由 ArgoCD 自动同步回退集群至上一健康版本。

【汇报输出规范】：
请一步一步执行并详细汇报每个步骤的执行进展。
在汇报的最末尾，请务必输出规范的 Markdown 卡片式【📌 流水线执行摘要 (Pipeline Summary)】，格式示例如下：
================================================================================
### 📌 流水线执行摘要 (Pipeline Summary)
- **代码仓库**: https://github.com/SDB-DevOps/ai-webhook.git (目标分支: [target-branch], 源分支: [source-branch])
- **Git Commit**: [target-branch 分支最新 commit SHA]
- **Helm AppVersion**: [k8s/Chart.yaml 中的 appVersion]
- **SonarQube 质量门禁**: ✅ PASSED / ❌ FAILED ([简要评分与问题数])
- **目标镜像**: [实际推送的镜像完整 Tag]
- **CI 阶段结果**: ✅ 成功 / ❌ 失败 ([简要说明])
- **CD 阶段结果**: ✅ 成功 (就绪状态) / ❌ 失败 ([简要说明])
- **自动修复状态**: 无需修复 / 已创建修复PR: [PR链接或分支名]
================================================================================