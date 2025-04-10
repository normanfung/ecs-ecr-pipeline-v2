# 🚀 Terraform ECS Project – Multi-Stage Infra & CI/CD

This project provisions a complete AWS ECS Fargate infrastructure with Terraform, separates infrastructure into **two logical stages**, and automates deployments via **GitHub Actions** workflows.

---

## 📦 Project Structure

```text
.
├── application/                      # Your Dockerized application code
│
├── terraform/
│   ├── stage1-infra/                # Core infrastructure setup
│   └── stage2-ecs/                  # ECS service + task definition
│
├── .github/
│   └── workflows/
│       ├── full-infra-deploy.yml   # End-to-end: infra + image + ECS
│       ├── docker-push.yml         # Just Docker image build & push
│       └── destroy-infra.yml       # Destroy both stage1 + stage2
│
├── .gitignore
└── README.md

```


---

## ⚙️ GitHub Actions Workflows

### ✅ `init-setup.yml` — Full Infra + App Deploy (Manual Trigger)
Run once at project Initialization

Provision everything:
- VPC, subnets, ECS cluster, IAM, ECR repo (stage1)
- Docker image build & push to ECR
- ECS service deployment using image tag (stage2)

> Triggered via `workflow_dispatch`.

---

---

### 🐳 `docker-push.yml` — Docker Image Build & Push
Used to:
- Build app Docker image from `./application`
- Push to ECR with both `latest` and `commit SHA` tags

> Ideal for CI/CD integration when only app code changes.

---

### 💣 `infra-destroy.yml` — Destroy Entire Infra Stack
- Destroys ECS service (stage2)
- Then destroys all infra (stage1)

---

## 🧪 Requirements (IMPORTANT)

- AWS Account + ECR permissions
- GitHub repo secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
- GitHub repository variable:
  - `ECR_REPO_NAME` (e.g., `my-app-repo`)
- S3 Backend Statefile Update for both stage1 and stage 2. Both can be found in the top portion of respective Main.tf.

---

## 🛠 Usage

### 1. Run Full Infra Deploy
Go to **Actions > Full Infra + App Deploy > Run Workflow**

This will:
- Apply stage1 Terraform - Provision Base Infra + CSR
- Build & push Docker image to CSR
- Apply stage2 Terraform - Provision ESC with Referenced Image

---

### 2. Push a New Docker Image
Go to **Actions > Docker Push > Run Workflow** (or set up auto-trigger on `main`)

---

### 3. Destroy All Resources
Go to **Actions > Destroy Infra > Run Workflow**  
This ensures proper destroy order (`stage2` → `stage1`)

---

## 🧼 Notes

- `stage2-ecs` depends on outputs from `stage1-infra` (via `terraform_remote_state`)
- ECR image cleanup is handled with `force_delete = true` or via manual AWS CLI commands
- Workflows use commit SHA (`github.sha`) for precise image tagging

---

## 🙌 Contributions

PRs and issues are welcome! Let's build clean, scalable AWS infra together 🚀