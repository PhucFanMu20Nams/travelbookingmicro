# Online Boutique → Travel Booking: Master Roadmap

> **Mục đích**: Roadmap tổng thể cho 3 mục tiêu refactor. Thực hiện theo thứ tự từ trên xuống.
> **Ước lượng tổng**: ~80-100 files bị ảnh hưởng | 3 phases | Effort: 3-5 sessions

---

## Tổng quan Architecture hiện tại

```
┌─────────────────────────────────────────────────────────────┐
│                      FRONTEND (Go)                          │
│  Routes: / | /product/{id} | /cart | /cart/checkout          │
│  Templates: home, product, cart, order, header, footer       │
│  gRPC clients → tất cả backend services                     │
└──────┬──────┬──────┬──────┬──────┬──────┬──────┬────────────┘
       │      │      │      │      │      │      │
       ▼      ▼      ▼      ▼      ▼      ▼      ▼
   Product  Cart  Currency Shipping Checkout Payment  Ad
   Catalog  Svc    Svc      Svc      Svc     Svc    Svc
    (Go)   (C#)   (JS)     (Go)     (Go)    (JS)  (Java)
       │                                      │
       ▼                                      ▼
   products    ┌──────────────┐          Email Svc
     .json     │  Redis Cart  │          (Python)
               └──────────────┘
                       ▲
                       │
              Recommendation Svc (Python)
```

**Proto**: `demo.proto` — package `hipstershop` — dùng chung cho tất cả services
**Generated code**: 4 ngôn ngữ (Go `genproto/`, Python `demo_pb2.py`, JS `proto/`, Java/C# trong build)

---

## Phase 1: Xoá GitLab CI (Mục tiêu 3) — DỄ NHẤT

| Metric | Value |
|--------|-------|
| **Files cần xoá** | 14 file `.gitlab-ci.yml` + 2 file Python SES |
| **Files cần sửa** | 0 |
| **Rủi ro** | Không rủi ro chức năng |
| **Thời gian** | ~15-30 phút |
| **Dependency** | Không có |

### Checklist nhanh
- [ ] Xoá 14 file `.gitlab-ci.yml` (11 services + eksinfra + oidc-setup + helm)
- [ ] Xoá 2 file SES dead code (`send_plan_email.py`, `send_outputs_email.py`)
- [ ] Verify: không có file nào import/reference các file đã xoá
- [ ] Commit: `chore: remove legacy GitLab CI configs and dead SES scripts`

**Chi tiết**: → Xem [PLAN-GOAL3-REMOVE-GITLAB-CI.md](./PLAN-GOAL3-REMOVE-GITLAB-CI.md)

---

## Phase 2: Bỏ Tools CI/CD không cần thiết (Mục tiêu 1) — DỄ

| Metric | Value |
|--------|-------|
| **Files cần sửa** | 13 workflow files + 1 docker-compose.yml |
| **Files cần xoá** | 1 workflow file + 1 Helm template + (optional) loadgenerator/ folder |
| **Files values.yaml** | 1 file Helm values cần sửa |
| **Rủi ro** | Thấp — cần kiểm tra `needs` dependency chain |
| **Thời gian** | ~1-2 giờ |
| **Dependency** | Nên hoàn thành Phase 1 trước (pipeline sạch hơn) |

### Checklist nhanh
- [ ] Xoá `sonar` job khỏi 11 service workflow files
- [ ] Cập nhật `needs` chain nếu có job depend vào `sonar`
- [ ] Xoá `go vet` step trong `security` job (3 Go services: frontend, productcatalogservice, shippingservice)
- [ ] Xoá `trx2junit` khỏi cartservice workflow
- [ ] Xoá loadgenerator: workflow file + docker-compose block + Helm template + values.yaml entry
- [ ] (Optional) Xoá toàn bộ folder `loadgenerator/`
- [ ] Xoá `send_plan_email.py` + `send_outputs_email.py` (nếu chưa xoá ở Phase 1)
- [ ] Verify: `docker compose up --build` vẫn hoạt động
- [ ] Commit: `chore: remove SonarCloud, go vet, trx2junit, Locust, and SES dead code`

**Chi tiết**: → Xem [PLAN-GOAL1-REMOVE-CI-TOOLS.md](./PLAN-GOAL1-REMOVE-CI-TOOLS.md)

---

## Phase 3: Chuyển sang Travel Booking (Mục tiêu 2) — KHÓ NHẤT

| Metric | Value |
|--------|-------|
| **Files cần sửa** | 50-80+ files |
| **Files cần tạo mới** | 5-15 files (ảnh, data mới, etc.) |
| **Ngôn ngữ ảnh hưởng** | Go, Python, JavaScript, C#, Java, HTML/CSS |
| **Rủi ro** | Cao — proto changes affect tất cả services |
| **Thời gian** | ~1-3 ngày |
| **Dependency** | Phase 1 & 2 hoàn thành |

### Chia thành 6 Sub-phases

```
Sub-phase 3A: Data Layer        → products.json + adservice data (thay sản phẩm)
Sub-phase 3B: UI Rebranding     → HTML templates, CSS, images, text
Sub-phase 3C: Frontend Logic    → handlers.go, main.go, rpc.go (đổi naming)
Sub-phase 3D: Proto Redesign    → demo.proto (ĐÂY LÀ BREAKING CHANGE)
Sub-phase 3E: Regenerate gRPC   → genproto.sh cho 8 services
Sub-phase 3F: Service Rebrand   → Variable naming, env vars, Helm charts, docker-compose
```

> **QUAN TRỌNG**: Sub-phase 3D-3E là rủi ro cao nhất. Có 2 strategy:
> 1. **Conservative** (Khuyến nghị): Giữ nguyên proto, chỉ đổi data + UI + text
> 2. **Full Rebrand**: Đổi proto package `hipstershop` → `travelbooking`, regenerate tất cả

**Chi tiết**: → Xem [PLAN-GOAL2-TRAVEL-BOOKING.md](./PLAN-GOAL2-TRAVEL-BOOKING.md)

---

## Dependency Graph

```
Phase 1 (GitLab CI)   Phase 2 (CI Tools)
       │                    │
       └────────┬───────────┘
                │
                ▼
        Phase 3 (Travel Booking)
         ┌──────┼──────┐
         │      │      │
         ▼      ▼      ▼
        3A     3B     3C    ← Có thể làm song song
         │      │      │
         └──────┼──────┘
                │
                ▼
               3D          ← BREAKING: Proto changes
                │
                ▼
               3E          ← Regenerate tất cả gRPC
                │
                ▼
               3F          ← Service rebrand + deploy config
```

---

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Proto change breaks gRPC communication | Cao (nếu đổi proto) | Critical | Strategy Conservative: giữ proto, chỉ đổi UI/data |
| Workflow `needs` chain bị gãy | Trung bình | Medium | Kiểm tra từng workflow trước khi commit |
| Helm template loadgenerator vẫn được reference | Thấp | Low | Grep toàn bộ workspace cho "loadgenerator" |
| Frontend templates render sai | Trung bình | Medium | Test bằng `docker compose up --build` sau mỗi sub-phase |
| genproto.sh fails (thiếu protoc tools) | Cao | High | Chỉ cần chạy nếu đổi proto. Test trên local trước |

---

## Verification Checklist (sau mỗi Phase)

### Sau Phase 1
```bash
git status               # Chỉ có deleted files, không có modified
grep -r "gitlab" .       # Không còn reference nào
```

### Sau Phase 2
```bash
docker compose up --build -d   # App vẫn chạy OK
# Kiểm tra http://localhost:8080 — UI hiển thị bình thường
# Grep cho các tool đã xoá:
grep -r "sonar\|SonarCloud\|trx2junit\|go vet\|loadgenerator" .github/
```

### Sau Phase 3
```bash
docker compose up --build -d   # App chạy với branding mới
# Kiểm tra http://localhost:8080 — Travel Booking UI
# Kiểm tra tất cả pages: /, /product/{id}, /cart, /cart/checkout
# Place a test order
```

---

## Git Branching Strategy

```
main
 ├── feat/remove-gitlab-ci          ← Phase 1
 ├── feat/cleanup-ci-tools          ← Phase 2
 └── feat/travel-booking            ← Phase 3
      ├── feat/travel-data          ← Sub-phase 3A
      ├── feat/travel-ui            ← Sub-phase 3B
      ├── feat/travel-frontend      ← Sub-phase 3C
      ├── feat/travel-proto         ← Sub-phase 3D-3E (nếu làm)
      └── feat/travel-deploy        ← Sub-phase 3F
```

---

## File Impact Summary

| Phase | Files Deleted | Files Modified | Files Created | Total Impact |
|-------|:------------:|:--------------:|:-------------:|:------------:|
| Phase 1 | 16 | 0 | 0 | 16 |
| Phase 2 | 2-4 | 13-15 | 0 | 15-19 |
| Phase 3 | 0 | 50-80 | 5-15 | 55-95 |
| **TOTAL** | **18-20** | **63-95** | **5-15** | **86-130** |
