# Phase 3: Chuyển sang Travel Booking — PLAN CHI TIẾT

> **Priority**: Làm SAU CÙNG (sau Phase 1 & 2)
> **Difficulty**: KHÓ — 50-80+ files, 4 ngôn ngữ, gRPC stack
> **Estimated time**: 1-3 ngày (chia thành 6 sub-phases)
> **Risk**: CAO nếu đổi proto; TRUNG BÌNH nếu dùng conservative approach

---

## Quyết định chiến lược quan trọng

### Strategy A: Conservative (KHUYẾN NGHỊ) — "UI/Data Rebrand Only"

Giữ nguyên proto definitions (`package hipstershop`, message names như `Product`, `Cart`, `CartItem`...). Chỉ thay đổi:
- Data layer (products.json → travel offerings)
- UI layer (HTML templates, CSS, images, text)
- Frontend naming/branding 
- docker-compose service names giữ nguyên

**Pros**: An toàn, nhanh, không cần regenerate gRPC code
**Cons**: Source code vẫn có naming "hipstershop", "product", "cart" bên trong

### Strategy B: Full Rebrand — "Everything Changes"

Đổi tất cả: proto package, message names, route paths, variable names...

**Pros**: Clean codebase, professional
**Cons**: Phải regenerate gRPC cho 8 services, 4 ngôn ngữ. Risk cao.

> **Recommendation**: Bắt đầu với Strategy A. Nếu muốn, làm Strategy B sau khi A đã stable.

---

## Sub-phase 3A: Data Layer (products.json + ad data)

> **Difficulty**: DỄ | **Files**: 2-3 | **Time**: 30 phút

### 3A.1: Thay đổi `productcatalogservice/products.json`

**TRƯỚC**: 9 sản phẩm e-commerce (Sunglasses, Tank Top, Watch, Loafers, Hairdryer, Candle Holder, Salt & Pepper Shakers, Bamboo Glass Jar, Mug)

**SAU**: 9 travel offerings (giữ nguyên cấu trúc JSON vì proto `Product` message format không đổi)

```json
{
    "products": [
        {
            "id": "FLIGHT-HCM-TYO",
            "name": "Ho Chi Minh → Tokyo Flight",
            "description": "Direct round-trip flight from Ho Chi Minh City to Tokyo Narita. Economy class, includes 23kg checked baggage.",
            "picture": "/static/img/products/flight-tokyo.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 450,
                "nanos": 0
            },
            "categories": ["flights", "asia"]
        },
        {
            "id": "HOTEL-BALI-LUX",
            "name": "Bali Luxury Resort — 5 Nights",
            "description": "5-night stay at a beachfront luxury resort in Seminyak, Bali. Includes breakfast and airport transfer.",
            "picture": "/static/img/products/hotel-bali.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 899,
                "nanos": 0
            },
            "categories": ["hotels", "asia", "luxury"]
        },
        {
            "id": "TOUR-HALONG-BAY",
            "name": "Ha Long Bay Day Tour",
            "description": "Full-day cruise through Ha Long Bay with lunch, kayaking, and cave exploration included.",
            "picture": "/static/img/products/tour-halong.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 79,
                "nanos": 990000000
            },
            "categories": ["tours", "asia", "adventure"]
        },
        {
            "id": "FLIGHT-LON-PAR",
            "name": "London → Paris Eurostar",
            "description": "High-speed rail ticket from London St Pancras to Paris Gare du Nord. Standard Premier class.",
            "picture": "/static/img/products/eurostar.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 189,
                "nanos": 0
            },
            "categories": ["flights", "europe", "rail"]
        },
        {
            "id": "HOTEL-TOKYO-CAP",
            "name": "Tokyo Capsule Hotel — 3 Nights",
            "description": "Unique capsule hotel experience in Shinjuku, Tokyo. Walking distance to major attractions.",
            "picture": "/static/img/products/hotel-capsule.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 120,
                "nanos": 0
            },
            "categories": ["hotels", "asia", "budget"]
        },
        {
            "id": "TOUR-SAFARI-KEN",
            "name": "Kenya Safari — 4 Days",
            "description": "4-day Masai Mara safari with game drives, accommodation in luxury tented camp, and all meals.",
            "picture": "/static/img/products/safari-kenya.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 1299,
                "nanos": 0
            },
            "categories": ["tours", "africa", "adventure", "luxury"]
        },
        {
            "id": "FLIGHT-NYC-MIA",
            "name": "New York → Miami Flight",
            "description": "One-way domestic flight from JFK to Miami International. Economy Plus with extra legroom.",
            "picture": "/static/img/products/flight-miami.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 159,
                "nanos": 990000000
            },
            "categories": ["flights", "domestic"]
        },
        {
            "id": "HOTEL-SWISS-SKI",
            "name": "Swiss Alps Ski Lodge — 7 Nights",
            "description": "Cozy ski lodge in Zermatt with Matterhorn views. Includes ski pass and daily breakfast.",
            "picture": "/static/img/products/hotel-swiss.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 2100,
                "nanos": 0
            },
            "categories": ["hotels", "europe", "luxury", "winter"]
        },
        {
            "id": "TOUR-MACHU-PICCHU",
            "name": "Machu Picchu Trek — 3 Days",
            "description": "3-day guided trek to Machu Picchu via the Inca Trail. Includes camping equipment, meals, and entrance fees.",
            "picture": "/static/img/products/tour-machu-picchu.jpg",
            "priceUsd": {
                "currencyCode": "USD",
                "units": 599,
                "nanos": 0
            },
            "categories": ["tours", "south-america", "adventure", "trekking"]
        }
    ]
}
```

### 3A.2: Thay đổi Ad Service data

**File**: `adservice/src/main/java/hipstershop/AdServiceServer.java` (hoặc tương đương)

Cần tìm và thay đổi ad data. Tìm file:
```bash
find adservice/ -name "*.java" | head -20
grep -r "AdService" adservice/src/ --include="*.java" -l
```

Thay đổi ad categories và ad text từ e-commerce → travel:
- "clothing" → "flights"
- "accessories" → "hotels"  
- "kitchen" → "tours"
- Ad text: đổi từ "sản phẩm" sang "travel deals"

### 3A.3: Thêm travel images

Cần thêm 9 ảnh mới vào `frontend/static/img/products/`:

```
frontend/static/img/products/
├── flight-tokyo.jpg       (placeholder hoặc stock image)
├── hotel-bali.jpg
├── tour-halong.jpg
├── eurostar.jpg
├── hotel-capsule.jpg
├── safari-kenya.jpg
├── flight-miami.jpg
├── hotel-swiss.jpg
└── tour-machu-picchu.jpg
```

> **Tip**: Có thể dùng placeholder images ban đầu (solid color rectangles), sau đó thay bằng real images.

### 3A Verification

```bash
# Validate JSON syntax
python3 -c "import json; json.load(open('productcatalogservice/products.json'))"
# Expected: no error

# Verify image paths match
cat productcatalogservice/products.json | python3 -c "
import json,sys
data=json.load(sys.stdin)
for p in data['products']:
    print(p['picture'])
"
# Check each path exists in frontend/static/
```

---

## Sub-phase 3B: UI Rebranding (HTML Templates + CSS)

> **Difficulty**: TRUNG BÌNH | **Files**: 8-12 | **Time**: 1-3 giờ

### 3B.1: Đổi tên website

**File**: `frontend/templates/header.html`

| Thay đổi | Trước | Sau |
|---------|-------|-----|
| `<title>` | `Online Boutique` | `Travel Booking` |
| Cymbal brand title | `Cymbal Shops` | `Travel Booking` |
| Logo (optional) | `Hipster_NavLogo.svg` | Có thể giữ hoặc đổi |

Cụ thể:
```html
<!-- TRƯỚC -->
<title>
    {{ if $.is_cymbal_brand }}
    Cymbal Shops
    {{ else }}
    Online Boutique
    {{ end }}
</title>

<!-- SAU -->
<title>Travel Booking</title>
```

### 3B.2: Đổi home page

**File**: `frontend/templates/home.html`

| Thay đổi | Trước | Sau |
|---------|-------|-----|
| Section title | `Hot Products` | `Featured Destinations` hoặc `Top Travel Deals` |
| Product card text | (tự động từ data, không cần sửa template) | (tự động) |

```html
<!-- TRƯỚC -->
<h3>Hot Products</h3>

<!-- SAU -->
<h3>Featured Travel Deals</h3>
```

### 3B.3: Đổi product page

**File**: `frontend/templates/product.html`

| Thay đổi | Trước | Sau |
|---------|-------|-----|
| Quantity label | `<select name="quantity">` (1-10) | Đổi label thành "Travelers" hoặc "Guests" |
| Button text | `Add To Cart` | `Book Now` hoặ `Add to Itinerary` |
| Packaging info section | Weight/dimensions | Xoá hoặc đổi thành "Trip Details" (duration, etc.) |

```html
<!-- TRƯỚC -->
<button type="submit" class="cymbal-button-primary">Add To Cart</button>

<!-- SAU -->
<button type="submit" class="cymbal-button-primary">Add to Itinerary</button>
```

Xoá hoặc giữ Packaging info section (product.html lines ~140-155):
```html
<!-- CÓ THỂ XOÁ TOÀN BỘ BLOCK NÀY nếu không cần -->
{{ if $.packagingInfo }}
<div class="product-packaging">
    <h3>Packaging</h3>
    ...
</div>
{{ end }}
```

### 3B.4: Đổi cart page

**File**: `frontend/templates/cart.html`

| Thay đổi | Trước | Sau |
|---------|-------|-----|
| Empty cart message | `Your shopping cart is empty!` | `Your travel itinerary is empty!` |
| Empty cart detail | `Items you add to your shopping cart will appear here.` | `Travel experiences you book will appear here.` |
| Header | `Cart (N)` | `Itinerary (N)` |
| Button | `Empty Cart` | `Clear Itinerary` |
| Button | `Continue Shopping` | `Explore More Destinations` |
| SKU label | `SKU #{{ .Item.Id }}` | `Booking #{{ .Item.Id }}` |
| Quantity label | `Quantity:` | `Travelers:` |
| Shipping section | `Shipping` | `Service Fee` hoặc `Booking Fee` |
| Section | `Shipping Address` | `Traveler Information` |
| Form fields | `Street Address`, `Zip Code`, etc. | Giữ nguyên (vẫn cần address cho billing) |
| Payment heading | `Payment Method` | Giữ nguyên |
| Button | `Place Order` | `Confirm Booking` |

Các thay đổi cụ thể trong cart.html:
```html
<!-- Thay đổi 1: Empty state -->
<h3>Your travel itinerary is empty!</h3>
<p>Travel experiences you book will appear here.</p>
<a class="cymbal-button-primary" href="{{ $.baseUrl }}/" role="button">Explore More Destinations</a>

<!-- Thay đổi 2: Cart header -->
<h3>Itinerary ({{ $.cart_size }})</h3>

<!-- Thay đổi 3: Buttons -->
<button class="cymbal-button-secondary cart-summary-empty-cart-button" type="submit">
    Clear Itinerary
</button>
<a class="cymbal-button-primary" href="{{ $.baseUrl }}/" role="button">
    Explore More
</a>

<!-- Thay đổi 4: Item details -->
<div class="col">
    Booking #{{ .Item.Id }}
</div>
<div class="col">
    Travelers: {{ .Quantity }}
</div>

<!-- Thay đổi 5: Shipping → Service Fee -->
<div class="col pl-md-0">Service Fee</div>

<!-- Thay đổi 6: Shipping Address → Billing Information -->
<h3>Billing Information</h3>

<!-- Thay đổi 7: Place Order → Confirm Booking -->
<button class="cymbal-button-primary" type="submit">
    Confirm Booking
</button>
```

### 3B.5: Đổi order confirmation page

**File**: `frontend/templates/order.html`

```html
<!-- TRƯỚC -->
<h3>Your order is complete!</h3>
<p>We've sent you a confirmation email.</p>

<!-- SAU -->
<h3>Your booking is confirmed!</h3>
<p>We've sent you a confirmation email with your travel details.</p>
```

```html
<!-- Thay đổi labels -->
Confirmation # → Booking Confirmation #
Tracking #     → Booking Reference #
Total Paid     → Total Paid (giữ nguyên)
Continue Shopping → Explore More Destinations
```

### 3B.6: Đổi header navigation

**File**: `frontend/templates/header.html`

```html
<!-- Cart icon tooltip -->
<!-- TRƯỚC -->
<img src="..." alt="Cart icon" class="logo" title="Cart" />

<!-- SAU -->
<img src="..." alt="Cart icon" class="logo" title="Itinerary" />
```

### 3B.7: Đổi footer

**File**: `frontend/templates/footer.html`

Kiểm tra footer.html xem có text e-commerce nào cần đổi không:
```bash
cat frontend/templates/footer.html
```

### 3B.8: Đổi recommendations section

**File**: `frontend/templates/recommendations.html`

Kiểm tra xem có text "Recommended Products" hay tương tự:
```bash
cat frontend/templates/recommendations.html
```

Đổi thành "You Might Also Like" hoặc "Recommended Destinations".

### 3B.9: (Optional) CSS Changes

**Files**: `frontend/static/styles/*.css`

- Banner color theme có thể đổi từ "shopping" → "travel" look & feel
- Background images trên home page (`.home-mobile-hero-banner`, `.home-desktop-left-image`)

### 3B Verification

```bash
docker compose up --build frontend
# Mở http://localhost:8080
# Kiểm tra:
# - [ ] Tên website = "Travel Booking"
# - [ ] Home page hiển thị "Featured Travel Deals"
# - [ ] Product page có button "Add to Itinerary"
# - [ ] Cart page có heading "Itinerary"
# - [ ] Checkout form vẫn hoạt động
# - [ ] Order confirmation đúng text mới
```

---

## Sub-phase 3C: Frontend Logic (Go code naming)

> **Difficulty**: TRUNG BÌNH | **Files**: 3-5 | **Time**: 1-2 giờ

### 3C.1: Đổi route paths (OPTIONAL — Strategy B only)

**File**: `frontend/main.go`

Nếu muốn đổi URL routes (Strategy B):
```go
// TRƯỚC
r.HandleFunc(baseUrl + "/product/{id}", svc.productHandler)
r.HandleFunc(baseUrl + "/cart", svc.viewCartHandler)
r.HandleFunc(baseUrl + "/cart", svc.addToCartHandler)
r.HandleFunc(baseUrl + "/cart/empty", svc.emptyCartHandler)
r.HandleFunc(baseUrl + "/cart/checkout", svc.placeOrderHandler)

// SAU (optional)
r.HandleFunc(baseUrl + "/offering/{id}", svc.productHandler)
r.HandleFunc(baseUrl + "/itinerary", svc.viewCartHandler)
r.HandleFunc(baseUrl + "/itinerary", svc.addToCartHandler)
r.HandleFunc(baseUrl + "/itinerary/clear", svc.emptyCartHandler)
r.HandleFunc(baseUrl + "/itinerary/checkout", svc.placeOrderHandler)
```

> **CẢNH BÁO**: Nếu đổi routes, cần update TẤT CẢ template links (href="/cart" → href="/itinerary"). Khuyến nghị: **KHÔNG đổi routes** ở Strategy A. Giữ nguyên /cart, /product, etc.

### 3C.2: Đổi cookie prefix (OPTIONAL)

**File**: `frontend/main.go`

```go
// TRƯỚC
cookiePrefix    = "shop_"
cookieSessionID = cookiePrefix + "session-id"
cookieCurrency  = cookiePrefix + "currency"

// SAU (optional)
cookiePrefix    = "travel_"
cookieSessionID = cookiePrefix + "session-id"
cookieCurrency  = cookiePrefix + "currency"
```

> **Lưu ý**: Nếu đổi cookie prefix, users hiện tại sẽ mất session. Không critical cho demo.

### 3C.3: Đổi log messages (OPTIONAL)

**File**: `frontend/handlers.go`

Các log messages có thể đổi nhưng không bắt buộc:
```go
// Ví dụ:
log.Debug("view user cart")           → log.Debug("view user itinerary")
log.Debug("placing order")           → log.Debug("confirming booking")
log.Debug("adding to cart")          → log.Debug("adding to itinerary")
```

### 3C.4: Đổi template data keys (KHÔNG NÊN)

**KHÔNG** đổi template data keys (`cart_size`, `shipping_cost`, etc.) vì chúng đã tied vào proto message fields. Giữ nguyên keys, chỉ đổi UI display text.

### 3C Verification

```bash
cd frontend && go build -o frontend . && cd ..
# Expected: build thành công, không có errors
```

---

## Sub-phase 3D: Proto Redesign (BREAKING CHANGE — Strategy B Only)

> **Difficulty**: KHÓ | **Files**: 3-6 proto files | **Time**: 2-4 giờ
> **CHỈ LÀM NẾU chọn Strategy B**

### CẢNH BÁO

⚠️ **Thay đổi proto sẽ BREAK tất cả gRPC communication cho đến khi regenerate code ở Sub-phase 3E.**

### 3D.1: Thay đổi demo.proto

Proto file chính: `currencyservice/proto/demo.proto` (master copy)
Các copy: `paymentservice/proto/demo.proto`, `adservice/src/main/proto/demo.proto`, `cartservice/src/protos/Cart.proto`

**Thay đổi cần làm**:

```protobuf
// TRƯỚC
package hipstershop;

// SAU
package travelbooking;  // hoặc giữ hipstershop nếu không muốn break
```

**Message renames** (optional, rủi ro CAO):
```protobuf
// Có thể đổi nhưng KHÔNG KHUYẾN NGHỊ ở phase đầu:
// Product → Offering
// Cart → Itinerary
// CartItem → ItineraryItem
// ShippingService → FulfillmentService
```

> **Khuyến nghị mạnh**: KHÔNG đổi message names. Chỉ đổi `package` nếu thực sự cần. Giữ nguyên message names cho an toàn.

### 3D.2: Sync proto cho tất cả services

Nếu đổi proto, cần copy file đã đổi tới TẤT CẢ nơi có proto:

```bash
# Master copy
cp currencyservice/proto/demo.proto paymentservice/proto/demo.proto
cp currencyservice/proto/demo.proto adservice/src/main/proto/demo.proto
# Cart proto riêng
# Edit cartservice/src/protos/Cart.proto separately
```

---

## Sub-phase 3E: Regenerate gRPC Code (Strategy B Only)

> **Difficulty**: KHÓ | **Files**: 8+ generated files | **Time**: 1-2 giờ + debugging
> **CHỈ LÀM NẾU đã làm Sub-phase 3D**

### Prerequisites

Cần cài đặt protoc tools trên local machine:

```bash
# Go
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Python
pip install grpcio-tools

# Node.js
npm install -g grpc-tools

# protoc compiler
brew install protobuf  # macOS
```

### 3E.1: Regenerate Go services (4 services)

```bash
# Frontend
cd frontend && bash genproto.sh && cd ..

# Checkout
cd checkoutservice && bash genproto.sh && cd ..

# ProductCatalog
cd productcatalogservice && bash genproto.sh && cd ..

# Shipping
cd shippingservice && bash genproto.sh && cd ..
```

**Kiểm tra genproto.sh syntax** — tất cả Go services dùng cùng pattern:
```bash
protoc --proto_path=$protodir --go_out=./$outdir --go_opt=paths=source_relative \
       --go-grpc_out=./$outdir --go-grpc_opt=paths=source_relative $protodir/demo.proto
```

> **VẤN ĐỀ**: genproto.sh references `../../protos/demo.proto` nhưng folder `protos/` không tồn tại ở root! Cần tạo folder `protos/` hoặc sửa path trong genproto.sh.

Kiểm tra:
```bash
ls -la protos/  # Expected: không tồn tại
```

**Giải pháp**: Tạo folder `protos/` ở root và copy demo.proto vào:
```bash
mkdir -p protos
cp currencyservice/proto/demo.proto protos/demo.proto
```

### 3E.2: Regenerate Python services (2 services)

```bash
# Email
cd emailservice && bash genproto.sh && cd ..

# Recommendation
cd recommendationservice && bash genproto.sh && cd ..
```

### 3E.3: Regenerate Node.js services (2 services)

```bash
# Currency
cd currencyservice && bash genproto.sh && cd ..

# Payment
cd paymentservice && bash genproto.sh && cd ..
```

### 3E.4: Java/C# services (build-time generation)

- **adservice** (Java): Proto compilation happens during Gradle build (`./gradlew build`)
- **cartservice** (C#): Proto compilation happens during `dotnet build` (configured in `.csproj`)

Không cần chạy genproto.sh riêng — chỉ cần rebuild Docker image.

### 3E Verification

```bash
# Build tất cả services
docker compose up --build -d

# Kiểm tra tất cả services healthy
docker compose ps
# Expected: tất cả services status "Up"

# Test gRPC communication
curl http://localhost:8080
# Expected: Travel Booking home page hiển thị
```

---

## Sub-phase 3F: Service Rebrand (Deploy Config)

> **Difficulty**: DỄ-TRUNG BÌNH | **Files**: 5-10 | **Time**: 30 phút - 1 giờ

### 3F.1: Docker Compose labeling

**File**: `docker-compose.yml`

Đổi comments:
```yaml
# TRƯỚC
# ============ Leaf services (no dependencies) ============

# SAU
# ============ Travel Booking Services (no dependencies) ============
```

### 3F.2: Helm Chart metadata

**File**: `helm/microservices-chart/Chart.yaml`

```yaml
# Đổi description nếu cần
name: microservices-chart
description: Travel Booking Microservices Application
```

### 3F.3: Helm values - Update image registries

**File**: `helm/microservices-chart/values.yaml`

Image repositories hiện tại trỏ tới GitLab registry:
```yaml
repository: registry.gitlab.com/seunayolu/gitops-frontend/frontend
```

Nên đổi thành GHCR:
```yaml
repository: ghcr.io/<your-org>/frontend
```

### 3F.4: README updates

**File**: `README.md`

Update README để reflect Travel Booking branding.

### 3F.5: Email templates

**File**: `emailservice/templates/`

Kiểm tra email templates:
```bash
ls emailservice/templates/
```

Đổi text trong confirmation email templates từ "order" → "booking".

### 3F.6: Locustfile (nếu giữ loadgenerator)

Nếu loadgenerator đã bị xoá ở Phase 2 → skip.

### 3F.7: ShoppingAssistant rebrand

**File**: `shoppingassistantservice/shoppingassistantservice.py`

Đổi context/prompts từ shopping → travel nếu có hardcoded text.

### 3F Verification

```bash
docker compose down -v
docker compose up --build -d

# Full test:
# 1. Mở http://localhost:8080 → Home page Travel Booking
# 2. Click vào 1 product → Travel offering page
# 3. Add to Itinerary
# 4. View Itinerary → Cart page with travel text
# 5. Place order → Confirm Booking
# 6. Order confirmation page → Booking confirmed
```

---

## Master File List — Tất cả files cần sửa (Strategy A)

### Data Layer (Sub-phase 3A)
| # | File | Action | Priority |
|:-:|------|--------|:--------:|
| 1 | `productcatalogservice/products.json` | Replace all products | P0 |
| 2 | `adservice/src/main/java/.../AdServiceServer.java` | Update ad data | P1 |
| 3-11 | `frontend/static/img/products/*.jpg` (9 files) | Add travel images | P1 |

### UI Templates (Sub-phase 3B)
| # | File | Action | Priority |
|:-:|------|--------|:--------:|
| 12 | `frontend/templates/header.html` | Title, nav text | P0 |
| 13 | `frontend/templates/home.html` | "Hot Products" → "Travel Deals" | P0 |
| 14 | `frontend/templates/product.html` | "Add To Cart" → "Add to Itinerary" | P0 |
| 15 | `frontend/templates/cart.html` | All cart text → itinerary text | P0 |
| 16 | `frontend/templates/order.html` | "Order complete" → "Booking confirmed" | P0 |
| 17 | `frontend/templates/recommendations.html` | Section title | P1 |
| 18 | `frontend/templates/footer.html` | If has e-commerce text | P2 |
| 19 | `frontend/templates/ad.html` | If has e-commerce text | P2 |

### Frontend Logic (Sub-phase 3C)
| # | File | Action | Priority |
|:-:|------|--------|:--------:|
| 20 | `frontend/main.go` | Cookie prefix (optional) | P2 |
| 21 | `frontend/handlers.go` | Log messages (optional) | P2 |

### CSS/Static Assets (Sub-phase 3B)
| # | File | Action | Priority |
|:-:|------|--------|:--------:|
| 22 | `frontend/static/styles/styles.css` | Color theme (optional) | P2 |
| 23 | `frontend/static/styles/cart.css` | (optional) | P2 |

### Deploy Config (Sub-phase 3F)
| # | File | Action | Priority |
|:-:|------|--------|:--------:|
| 24 | `docker-compose.yml` | Comments update | P2 |
| 25 | `helm/microservices-chart/Chart.yaml` | Description | P2 |
| 26 | `helm/microservices-chart/values.yaml` | Image repos (GHCR) | P1 |
| 27 | `README.md` | Full rewrite | P1 |
| 28 | `emailservice/templates/*.html` | Email text | P1 |

**Total Strategy A: ~28 files** (so với 50-80+ nếu Strategy B)

---

## Master File List — Additional files (Strategy B Only)

### Proto Files
| # | File | Action |
|:-:|------|--------|
| 29 | `currencyservice/proto/demo.proto` | Change package name |
| 30 | `paymentservice/proto/demo.proto` | Sync from master |
| 31 | `adservice/src/main/proto/demo.proto` | Sync from master |
| 32 | `cartservice/src/protos/Cart.proto` | Change package name |

### Generated gRPC Code (regenerated, not manually edited)
| # | File | Action |
|:-:|------|--------|
| 33-34 | `frontend/genproto/demo.pb.go`, `demo_grpc.pb.go` | Regenerate |
| 35-36 | `checkoutservice/genproto/demo.pb.go`, `demo_grpc.pb.go` | Regenerate |
| 37-38 | `productcatalogservice/genproto/demo.pb.go`, `demo_grpc.pb.go` | Regenerate |
| 39-40 | `shippingservice/genproto/demo.pb.go`, `demo_grpc.pb.go` | Regenerate |
| 41-42 | `emailservice/demo_pb2.py`, `demo_pb2_grpc.py` | Regenerate |
| 43-44 | `recommendationservice/demo_pb2.py`, `demo_pb2_grpc.py` | Regenerate |

### Service Code (import path updates)
| # | File | Action |
|:-:|------|--------|
| 45 | `frontend/handlers.go` | Update proto import package name |
| 46 | `frontend/rpc.go` | Update proto import package name |
| 47 | `frontend/main.go` | Update proto import package name |
| 48 | `checkoutservice/main.go` | Update proto import package name |
| 49 | `productcatalogservice/server.go` | Update proto import package name |
| 50 | `productcatalogservice/product_catalog.go` | Update proto import |
| 51 | `productcatalogservice/catalog_loader.go` | Update proto import |
| 52 | `shippingservice/main.go` | Update proto import |
| 53 | `shippingservice/quote.go` | Update proto import |
| 54 | `shippingservice/tracker.go` | Update proto import |
| 55 | `emailservice/email_server.py` | Update proto import |
| 56 | `recommendationservice/recommendation_server.py` | Update proto import |
| 57 | `currencyservice/server.js` | Update proto import |
| 58 | `paymentservice/server.js` | Update proto import |
| 59 | `paymentservice/charge.js` | Update proto import |

**Total Strategy B: ~60 files**

---

## Recommended Order of Execution

```
1. Sub-phase 3A: products.json + images                    (30 min)
   ├── docker compose up --build → test product display
   └── COMMIT: "feat: replace e-commerce products with travel offerings"

2. Sub-phase 3B: HTML templates text changes               (1-2 hours)
   ├── header.html → title
   ├── home.html → section title
   ├── product.html → button text
   ├── cart.html → all text replacements
   ├── order.html → confirmation text
   ├── docker compose up --build → test all pages
   └── COMMIT: "feat: rebrand UI from Online Boutique to Travel Booking"

3. Sub-phase 3C: Frontend Go code (optional)               (30 min)
   ├── Cookie prefix
   ├── Log messages
   ├── go build → verify
   └── COMMIT: "refactor: update frontend code naming for travel domain"

4. Sub-phase 3F: Deploy config + README                    (30 min)
   ├── docker-compose comments
   ├── Helm Chart.yaml
   ├── README.md
   ├── Email templates
   └── COMMIT: "chore: update deployment configs and docs for Travel Booking"

────────── STOP HERE IF STRATEGY A ──────────

5. Sub-phase 3D: Proto changes                              (2 hours)
   └── COMMIT: "feat!: rename proto package to travelbooking"

6. Sub-phase 3E: Regenerate gRPC + fix imports             (2 hours)
   ├── Run genproto.sh for all services
   ├── Fix all import paths
   ├── docker compose up --build → full integration test
   └── COMMIT: "feat: regenerate gRPC code for new proto package"
```

---

## Troubleshooting Guide

### Problem: Product images don't show
```bash
# Kiểm tra image path trong products.json match với file thực tế
ls frontend/static/img/products/
# Kiểm tra Dockerfile có COPY static folder
grep -n "static" frontend/Dockerfile
```

### Problem: gRPC connection failed after proto change
```bash
# Kiểm tra tất cả services dùng cùng version proto
diff currencyservice/proto/demo.proto paymentservice/proto/demo.proto
# Rebuild tất cả
docker compose down -v && docker compose up --build -d
```

### Problem: Frontend template error
```bash
# Kiểm tra Go template syntax
docker compose logs frontend | grep "template"
# Phổ biến nhất: quên đóng {{ end }}
```

### Problem: Cart/Checkout broken
```bash
# Kiểm tra cartservice connection
docker compose logs cartservice
# Kiểm tra Redis
docker compose exec redis-cart redis-cli ping
```
