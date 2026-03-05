# Phase 1: Xoá GitLab CI — PLAN CHI TIẾT

> **Priority**: Làm TRƯỚC TIÊN
> **Difficulty**: DỄ — chỉ xoá files
> **Estimated time**: 15-30 phút
> **Risk**: ZERO — không ảnh hưởng chức năng app

---

## Bối cảnh

Project đã migrate hoàn toàn từ GitLab CI sang GitHub Actions. Hiện tại tồn tại **14 file `.gitlab-ci.yml`** — đây là dead config, không còn được sử dụng. Ngoài ra, 2 file Python dùng AWS SES để gửi email từ GitLab pipeline (`send_plan_email.py`, `send_outputs_email.py`) cũng là dead code vì chúng reference biến GitLab CI (`$CI_PIPELINE_ID`, `$CI_PROJECT_NAME`, etc.).

### Tại sao xoá an toàn?
- GitHub Actions workflows (`/.github/workflows/`) đã cover **tất cả** 11 services + `eksinfra` + `oidc-setup`
- Helm deployment được handle bởi job `update-helm` trong mỗi service workflow
- Không có file nào trong app code import hoặc reference `.gitlab-ci.yml`
- SES scripts dùng `$CI_PIPELINE_ID` (GitLab-only variable) → vô dụng trên GitHub Actions

---

## Danh sách files cần XOÁ (16 files)

### 14 files `.gitlab-ci.yml`

| # | File Path | Dòng | Ghi chú |
|:-:|-----------|:----:|---------|
| 1 | `adservice/.gitlab-ci.yml` | ~160 | Java/Gradle pipeline + SonarCloud |
| 2 | `cartservice/.gitlab-ci.yml` | ~150 | .NET pipeline + trx2junit + SonarCloud |
| 3 | `checkoutservice/.gitlab-ci.yml` | ~150 | Go pipeline + SonarCloud |
| 4 | `currencyservice/.gitlab-ci.yml` | ~150 | Node.js pipeline + SonarCloud |
| 5 | `emailservice/.gitlab-ci.yml` | ~150 | Python pipeline + SonarCloud |
| 6 | `frontend/.gitlab-ci.yml` | ~160 | Go pipeline + go vet + SonarCloud |
| 7 | `loadgenerator/.gitlab-ci.yml` | ~150 | Python pipeline + Bandit + SonarCloud |
| 8 | `paymentservice/.gitlab-ci.yml` | ~150 | Node.js pipeline + SonarCloud |
| 9 | `productcatalogservice/.gitlab-ci.yml` | ~150 | Go pipeline + go vet + SonarCloud |
| 10 | `recommendationservice/.gitlab-ci.yml` | ~150 | Python pipeline + Safety + SonarCloud |
| 11 | `shippingservice/.gitlab-ci.yml` | ~150 | Go pipeline + go vet + SonarCloud |
| 12 | `eksinfra/.gitlab-ci.yml` | ~120 | Terraform pipeline (init/validate/plan/apply/destroy) |
| 13 | `oidc-setup/.gitlab-ci.yml` | ~100 | Terraform OIDC setup pipeline |
| 14 | `helm/.gitlab-ci.yml` | ~110 | Helm lint/package/deploy pipeline |

### 2 files SES Dead Code

| # | File Path | Dòng | Ghi chú |
|:-:|-----------|:----:|---------|
| 15 | `eksinfra/send_plan_email.py` | ~55 | Dùng `$CI_PIPELINE_ID`, `$CI_PROJECT_NAME` — GitLab-only biến |
| 16 | `eksinfra/send_outputs_email.py` | ~55 | Tương tự — gửi email sau terraform apply |

---

## Thứ tự thực hiện (Step-by-step)

### Step 1: Verify trước khi xoá

Chạy lệnh này trong terminal để xác nhận không có file nào reference `.gitlab-ci.yml`:

```bash
# Kiểm tra xem có file nào import/reference .gitlab-ci.yml không
grep -r "gitlab-ci" --include="*.go" --include="*.py" --include="*.js" --include="*.ts" --include="*.yaml" --include="*.yml" --include="*.json" --include="*.sh" --include="*.html" . | grep -v ".gitlab-ci.yml" | grep -v ".git/"
```

**Expected**: Không có kết quả hoặc chỉ có references trong README/docs (không critical).

### Step 2: Verify SES scripts không được reference

```bash
# Kiểm tra ai gọi send_plan_email.py hoặc send_outputs_email.py
grep -r "send_plan_email\|send_outputs_email" --include="*.yml" --include="*.yaml" --include="*.sh" --include="*.py" . | grep -v "send_plan_email.py" | grep -v "send_outputs_email.py"
```

**Expected**: Không có kết quả. Scripts này chỉ được gọi (nếu có) bên trong GitLab CI pipeline đã bị disable.

### Step 3: Xoá 14 files `.gitlab-ci.yml`

```bash
# Xoá tất cả .gitlab-ci.yml files
rm adservice/.gitlab-ci.yml
rm cartservice/.gitlab-ci.yml
rm checkoutservice/.gitlab-ci.yml
rm currencyservice/.gitlab-ci.yml
rm emailservice/.gitlab-ci.yml
rm frontend/.gitlab-ci.yml
rm loadgenerator/.gitlab-ci.yml
rm paymentservice/.gitlab-ci.yml
rm productcatalogservice/.gitlab-ci.yml
rm recommendationservice/.gitlab-ci.yml
rm shippingservice/.gitlab-ci.yml
rm eksinfra/.gitlab-ci.yml
rm oidc-setup/.gitlab-ci.yml
rm helm/.gitlab-ci.yml
```

Hoặc one-liner:

```bash
find . -name ".gitlab-ci.yml" -type f -delete
```

### Step 4: Xoá 2 files SES

```bash
rm eksinfra/send_plan_email.py
rm eksinfra/send_outputs_email.py
```

### Step 5: Verify sau khi xoá

```bash
# Verify: không còn .gitlab-ci.yml nào
find . -name ".gitlab-ci.yml" -type f
# Expected: no output

# Verify: không còn SES scripts
ls eksinfra/send_*.py 2>/dev/null
# Expected: "No such file or directory"

# Verify: GitHub Actions workflows vẫn nguyên vẹn
ls .github/workflows/
# Expected: 13 files (.yml)

# Verify: app vẫn build được (optional nhưng khuyến nghị)
docker compose build --parallel 2>&1 | tail -5
```

### Step 6: Commit

```bash
git add -A
git commit -m "chore: remove legacy GitLab CI configs and dead SES email scripts

- Remove 14 .gitlab-ci.yml files (superseded by GitHub Actions workflows)
- Remove send_plan_email.py and send_outputs_email.py (dead code using GitLab CI variables)
- No functional changes to the application"
```

---

## Lưu ý đặc biệt

### Về `helm/.gitlab-ci.yml`
File này chứa pipeline cho Helm deployment (lint → package → deploy → verify). Trên GitHub Actions, Helm updates được handle bởi job `update-helm` trong mỗi service workflow — nó gọi script `.github/scripts/update-helm-values-pr.sh` để tự động update Helm values và mở PR. Do đó, GitLab CI Helm pipeline **hoàn toàn redundant**.

### Về `eksinfra/.gitlab-ci.yml`
Terraform pipeline GitLab (dùng OIDC token `GITLAB_OIDC_TOKEN`) đã được thay thế bởi `eksinfra.yml` GitHub Actions workflow (dùng `aws-actions/configure-aws-credentials@v4` với `role-to-assume`). Safe to delete.

### Về `oidc-setup/.gitlab-ci.yml`
Tương tự — sử dụng AWS Access Key trực tiếp (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`) thay vì OIDC, đã chuyển sang GitHub Actions.

---

## Verification Matrix

| Verification | Command | Expected Result |
|-------------|---------|-----------------|
| No `.gitlab-ci.yml` remaining | `find . -name ".gitlab-ci.yml"` | Empty output |
| No SES scripts remaining | `ls eksinfra/send_*.py` | "No such file" |
| GitHub Actions intact | `ls .github/workflows/*.yml \| wc -l` | 13 |
| No broken references | `grep -r "gitlab-ci" . --include="*.yml"` | Empty (hoặc chỉ docs) |
| App still works | `docker compose up --build -d` | All services healthy |

---

## Rollback Plan

Nếu bất kỳ vấn đề nào xảy ra (rất unlikely):

```bash
git revert HEAD  # Undo commit xoá files
```

Hoặc recover từng file:

```bash
git checkout HEAD~1 -- adservice/.gitlab-ci.yml
# ... repeat for each file
```
