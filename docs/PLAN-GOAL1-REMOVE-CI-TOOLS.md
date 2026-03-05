# Phase 2: Bỏ CI/CD Tools không cần thiết — PLAN CHI TIẾT

> **Priority**: Làm SAU Phase 1 (xoá GitLab CI)
> **Difficulty**: DỄ-TRUNG BÌNH
> **Estimated time**: 1-2 giờ
> **Risk**: Thấp — cần kiểm tra job dependency chain

---

## Bối cảnh

Hiện tại các GitHub Actions workflows chứa nhiều tools/services không cần thiết cho project:
1. **SonarCloud** — code quality scan, tốn secrets/setup, không essential
2. **go vet** — Go static analysis, redundant với SonarCloud (cả 2 đều sẽ bỏ)
3. **trx2junit** — .NET test result converter, chỉ dùng trong cartservice
4. **Locust/Load Generator** — load testing service, không cần cho app hoạt động
5. **AWS SES scripts** — dead code (đã cover ở Phase 1, nhắc lại cho completeness)

---

## Tool 1: Xoá SonarCloud (11 workflow files)

### Phạm vi ảnh hưởng

SonarCloud tồn tại dưới dạng **job `sonar`** trong 11 service workflow files:

| # | Workflow File | Sonar Job Pattern | Job `needs` sonar? |
|:-:|--------------|-------------------|:------------------:|
| 1 | `.github/workflows/adservice.yml` | `sonar` job (gradle sonar) | Không — `package` chạy trên `push`, `sonar` chạy trên `pull_request` |
| 2 | `.github/workflows/cartservice.yml` | `sonar` job (dotnet-sonarscanner) | Không — tách biệt event |
| 3 | `.github/workflows/checkoutservice.yml` | `sonar` job (SonarSource action) | Không |
| 4 | `.github/workflows/currencyservice.yml` | `sonar` job (SonarSource action) | Không |
| 5 | `.github/workflows/emailservice.yml` | `sonar` job (SonarSource action) | Không |
| 6 | `.github/workflows/frontend.yml` | `sonar` job (SonarSource action) | Không |
| 7 | `.github/workflows/loadgenerator.yml` | `sonar` job (SonarSource action) | Không |
| 8 | `.github/workflows/paymentservice.yml` | `sonar` job (SonarSource action) | Không |
| 9 | `.github/workflows/productcatalogservice.yml` | `sonar` job (SonarSource action) | Không |
| 10 | `.github/workflows/recommendationservice.yml` | `sonar` job (SonarSource action) | Không |
| 11 | `.github/workflows/shippingservice.yml` | `sonar` job (SonarSource action) | Không |

### Phân tích dependency chain (QUAN TRỌNG)

Kiểm tra pattern trong mỗi workflow:

```
PR event:    build → test + security → sonar        (sonar là leaf node, không ai depends on nó)
Push event:  package → update-helm                   (hoàn toàn tách biệt)
```

**Kết luận**: Job `sonar` KHÔNG được depend on bởi bất kỳ job nào khác. An toàn để xoá.

### Hành động cho từng file

Có **3 patterns** khác nhau cần handle:

#### Pattern A: SonarSource GitHub Action (8 services)
**Files**: checkoutservice, currencyservice, emailservice, frontend, loadgenerator, paymentservice, productcatalogservice, recommendationservice, shippingservice

```yaml
# XOÁ TOÀN BỘ BLOCK NÀY (khoảng 18-20 dòng):
  sonar:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: [test, security]        # hoặc needs: test
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@v3
        with:
          projectBaseDir: <service-name>
          args: >
            -Dsonar.projectKey=...
            -Dsonar.organization=...
            -Dsonar.host.url=...
            -Dsonar.sources=.
            -Dsonar.exclusions=...
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Pattern B: Gradle SonarQube (adservice)
```yaml
# XOÁ TOÀN BỘ BLOCK NÀY:
  sonar:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: build
    env:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      SONAR_ORGANIZATION: ${{ vars.SONAR_ORGANIZATION }}
      SONAR_PROJECT_KEY: ${{ vars.SONAR_ORGANIZATION }}_online-boutique_adservice
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'
      - uses: gradle/actions/setup-gradle@v4
      - name: Sonar Scan
        working-directory: adservice
        run: ./gradlew sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.token=${SONAR_TOKEN}
```

Ngoài ra, xoá env variable `SONAR_HOST_URL` ở level `env:` top-level trong `adservice.yml`:
```yaml
env:
  SERVICE_NAME: adservice
  GHCR_ORG: ${{ vars.GHCR_ORG || github.repository_owner }}
  SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL || 'https://sonarcloud.io' }}  # ← XOÁ DÒNG NÀY
```

#### Pattern C: dotnet-sonarscanner (cartservice)
```yaml
# XOÁ TOÀN BỘ BLOCK NÀY:
  sonar:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: test
    env:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
      SONAR_ORGANIZATION: ${{ vars.SONAR_ORGANIZATION }}
      SONAR_PROJECT_KEY: ${{ vars.SONAR_ORGANIZATION }}_online-boutique_cartservice
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.0.x'
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
      - name: Install SonarScanner
        run: dotnet tool install --global dotnet-sonarscanner
      - name: Sonar Scan
        run: |
          export PATH="$PATH:/home/runner/.dotnet/tools"
          dotnet sonarscanner begin /k:"${SONAR_PROJECT_KEY}" /o:"${SONAR_ORGANIZATION}" /d:sonar.host.url="${SONAR_HOST_URL}" /d:sonar.token="${SONAR_TOKEN}"
          dotnet build cartservice/cartservice.sln --configuration Release
          dotnet sonarscanner end /d:sonar.token="${SONAR_TOKEN}"
```

Ngoài ra, xoá env variable `SONAR_HOST_URL` ở level `env:` top-level trong `cartservice.yml`:
```yaml
env:
  SERVICE_NAME: cartservice
  GHCR_ORG: ${{ vars.GHCR_ORG || github.repository_owner }}
  SONAR_HOST_URL: ${{ vars.SONAR_HOST_URL || 'https://sonarcloud.io' }}  # ← XOÁ DÒNG NÀY
```

---

## Tool 2: Xoá `go vet` (3 workflow files)

### Phạm vi ảnh hưởng

`go vet` nằm trong job `security` của 3 Go services:

| # | Workflow File | Security Job nội dung |
|:-:|--------------|----------------------|
| 1 | `.github/workflows/frontend.yml` | **CHỈ CÓ** `go vet` → xoá TOÀN BỘ job `security` |
| 2 | `.github/workflows/productcatalogservice.yml` | **CHỈ CÓ** `go vet` → xoá TOÀN BỘ job `security` |
| 3 | `.github/workflows/shippingservice.yml` | **CHỈ CÓ** `go vet` → xoá TOÀN BỘ job `security` |

### Phân tích: Xoá cả job `security` hay chỉ xoá step?

Kiểm tra nội dung job `security` trong cả 3 files:

```yaml
  security:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: build
    continue-on-error: true
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24.3'
      - name: go vet
        working-directory: <service>
        run: go vet ./... || true
```

**Job `security` CHỈ chứa 1 step duy nhất** (`go vet`). → **Xoá TOÀN BỘ job `security`**.

### Kiểm tra dependency: Ai `needs: security`?

Trong cả 3 files, `sonar` job có `needs: [test, security]`. Nhưng vì ta cũng xoá `sonar`, nên **không cần cập nhật `needs` chain** — cả 2 jobs biến mất cùng lúc.

### Hành động

Xoá toàn bộ block job `security` (~12-14 dòng) trong mỗi file:

```yaml
# XOÁ TOÀN BỘ BLOCK NÀY trong frontend.yml, productcatalogservice.yml, shippingservice.yml:
  security:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: build
    continue-on-error: true
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24.3'
      - name: go vet
        working-directory: <service-name>
        run: go vet ./... || true
```

---

## Tool 3: Xoá `trx2junit` (1 workflow file)

### Phạm vi ảnh hưởng

**File**: `.github/workflows/cartservice.yml` — job `test`

### Hành động

Trong job `test` của `cartservice.yml`, thay đổi:

**TRƯỚC** (xoá các phần gạch đỏ):
```yaml
  test:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.0.x'
      - name: Install trx2junit                        # ← XOÁ STEP NÀY
        run: dotnet tool install --global trx2junit     # ← XOÁ
      - name: Run tests
        run: |
          export PATH="$PATH:/home/runner/.dotnet/tools"  # ← XOÁ (chỉ cần cho trx2junit)
          dotnet restore cartservice/cartservice.sln
          dotnet test cartservice/cartservice.sln --configuration Release --logger trx --results-directory cartservice/TestResults
          trx2junit cartservice/TestResults/*.trx         # ← XOÁ DÒNG NÀY
      - name: Upload test results                        # ← XOÁ STEP NÀY
        uses: actions/upload-artifact@v4                  # ← XOÁ
        with:                                             # ← XOÁ
          name: cartservice-test-results                  # ← XOÁ
          path: cartservice/TestResults/                  # ← XOÁ
```

**SAU**:
```yaml
  test:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.0.x'
      - name: Run tests
        run: |
          dotnet restore cartservice/cartservice.sln
          dotnet test cartservice/cartservice.sln --configuration Release
```

---

## Tool 4: Xoá Locust/Load Generator (nhiều files)

### Phạm vi ảnh hưởng

| # | File | Hành động | Chi tiết |
|:-:|------|-----------|----------|
| 1 | `.github/workflows/loadgenerator.yml` | **XOÁ FILE** | Toàn bộ workflow |
| 2 | `docker-compose.yml` | **SỬA** | Xoá block `loadgenerator:` (~12 dòng) |
| 3 | `helm/microservices-chart/templates/loadgenerator.yaml` | **XOÁ FILE** | Helm template |
| 4 | `helm/microservices-chart/values.yaml` | **SỬA** | Xoá block `loadgenerator:` (~12 dòng) |
| 5 | `loadgenerator/` folder | **XOÁ FOLDER** (optional) | Toàn bộ source code |

### Step 4a: Xoá workflow file

```bash
rm .github/workflows/loadgenerator.yml
```

### Step 4b: Sửa `docker-compose.yml`

Xoá block loadgenerator (~12 dòng):
```yaml
  # ============ Load Generator (optional) ============

  loadgenerator:
    build:
      context: ./loadgenerator
      dockerfile: Dockerfile
    environment:
      - FRONTEND_ADDR=frontend:8080
      - USERS=10
      - RATE=1
    depends_on:
      - frontend
    networks:
      - boutique
```

Cũng xoá comment header nếu muốn clean hơn.

### Step 4c: Xoá Helm template

```bash
rm helm/microservices-chart/templates/loadgenerator.yaml
```

### Step 4d: Sửa Helm `values.yaml`

Xoá block trong `helm/microservices-chart/values.yaml`:
```yaml
  loadgenerator:
    image:
      repository: registry.gitlab.com/seunayolu/gitops-loadgenerator/loadgenerator
      tag: "fabd1cf7"
    replicas: 1
    users: "10"
    rate: "1"
    resources:
      requests:
        cpu: 300m
        memory: 256Mi
      limits:
        cpu: 500m
        memory: 512Mi
```

### Step 4e: Xoá folder `loadgenerator/` (optional nhưng khuyến nghị)

```bash
rm -rf loadgenerator/
```

**Files bên trong folder** (sẽ bị xoá):
- `loadgenerator/Dockerfile`
- `loadgenerator/locustfile.py`
- `loadgenerator/requirements.in`
- `loadgenerator/requirements.txt`
- `loadgenerator/.gitlab-ci.yml` (đã xoá ở Phase 1)

### Step 4f: Verify loadgenerator đã sạch

```bash
grep -r "loadgenerator" . --include="*.yml" --include="*.yaml" --include="*.go" --include="*.py" | grep -v ".git/" | grep -v "docs/"
```

**Expected**: Có thể còn trong `helm/kubernetes-manifests-final/` — đây là static manifests, xoá nếu muốn.

---

## Tool 5: Xoá AWS SES Scripts (nếu chưa xoá ở Phase 1)

Nếu Phase 1 đã xoá, skip. Nếu chưa:

```bash
rm eksinfra/send_plan_email.py
rm eksinfra/send_outputs_email.py
```

---

## Thứ tự thực hiện TỔNG (Step-by-step)

### Step 1: Xoá SonarCloud job khỏi 11 workflow files

Lần lượt mở từng file và xoá block `sonar:` job:

```
1.  .github/workflows/adservice.yml           → Xoá sonar job + SONAR_HOST_URL env
2.  .github/workflows/cartservice.yml         → Xoá sonar job + SONAR_HOST_URL env
3.  .github/workflows/checkoutservice.yml     → Xoá sonar job
4.  .github/workflows/currencyservice.yml     → Xoá sonar job
5.  .github/workflows/emailservice.yml        → Xoá sonar job
6.  .github/workflows/frontend.yml            → Xoá sonar job
7.  .github/workflows/loadgenerator.yml       → SẼ XOÁ CẢ FILE (Step 4a)
8.  .github/workflows/paymentservice.yml      → Xoá sonar job
9.  .github/workflows/productcatalogservice.yml → Xoá sonar job
10. .github/workflows/recommendationservice.yml → Xoá sonar job
11. .github/workflows/shippingservice.yml     → Xoá sonar job
```

### Step 2: Xoá `security` job (go vet) khỏi 3 Go workflow files

```
1. .github/workflows/frontend.yml            → Xoá security job
2. .github/workflows/productcatalogservice.yml → Xoá security job
3. .github/workflows/shippingservice.yml      → Xoá security job
```

### Step 3: Sửa cartservice workflow (trx2junit)

```
1. .github/workflows/cartservice.yml → Simplify test job
```

### Step 4: Xoá loadgenerator

```
1. rm .github/workflows/loadgenerator.yml
2. Sửa docker-compose.yml
3. rm helm/microservices-chart/templates/loadgenerator.yaml
4. Sửa helm/microservices-chart/values.yaml
5. rm -rf loadgenerator/
```

### Step 5: Verify comprehensive

```bash
# 1. Kiểm tra không còn SonarCloud
grep -r "sonar\|SonarCloud\|sonarscanner" .github/workflows/
# Expected: empty

# 2. Kiểm tra không còn go vet
grep -r "go vet" .github/workflows/
# Expected: empty

# 3. Kiểm tra không còn trx2junit
grep -r "trx2junit" .github/workflows/
# Expected: empty

# 4. Kiểm tra không còn loadgenerator
grep -r "loadgenerator" .github/workflows/ docker-compose.yml
# Expected: empty

# 5. App vẫn chạy
docker compose up --build -d
# Truy cập http://localhost:8080
```

### Step 6: Commit

```bash
git add -A
git commit -m "chore: remove SonarCloud, go vet, trx2junit, and Locust load generator

- Remove SonarCloud scan job from 11 service workflows
- Remove go vet security job from 3 Go service workflows
- Simplify cartservice test job (remove trx2junit dependency)
- Remove loadgenerator: workflow, docker-compose block, Helm chart, and source folder
- No functional changes to the application"
```

---

## Summary: Trạng thái workflow sau khi clean

### TRƯỚC (mỗi service workflow - PR event)
```
build → test + security → sonar
```

### SAU (mỗi service workflow - PR event)

**Go services** (frontend, productcatalogservice, shippingservice, checkoutservice):
```
build → test
```

**Python services** (emailservice, recommendationservice):
```
build → test + security (bandit/safety - GIỮ LẠI)
```

**Node.js services** (currencyservice, paymentservice):
```
build → test + security (npm audit - GIỮ LẠI)
```

**Java service** (adservice):
```
build
```

**C# service** (cartservice):
```
build → test
```

> **Note**: Các job `security` (Bandit, npm audit, Safety) của Python/Node.js services KHÔNG bị xoá — chúng là lightweight và hữu ích. Chỉ xoá `go vet` vì nó redundant.

---

## Edge Cases cần lưu ý

### 1. Biến `SONAR_HOST_URL` ở top-level env

Chỉ 2 files có biến này ở top-level: `adservice.yml` và `cartservice.yml`.
Cần xoá dòng `SONAR_HOST_URL` khỏi block `env:` ở đầu file.

### 2. `checkoutservice.yml` — sonar needs pattern

```yaml
  sonar:
    needs: test    # ← chỉ depend test, không có security
```
Không có job `security` trong checkout workflow → chỉ xoá `sonar` là đủ.

### 3. `helm/kubernetes-manifests-final/`

Có thể chứa static loadgenerator manifest. Kiểm tra:
```bash
ls helm/kubernetes-manifests-final/ | grep loadgenerator
```
Nếu có → xoá.

### 4. GitHub Secrets & Vars sau clean

Sau khi xoá SonarCloud, các secrets/vars sau KHÔNG CÒN ĐƯỢC SỬ DỤNG trên GitHub:
- `SONAR_TOKEN` (secret)
- `SONAR_ORGANIZATION` (variable)
- `SONAR_HOST_URL` (variable)

Có thể xoá chúng từ GitHub Settings → Secrets/Variables để giữ sạch.
