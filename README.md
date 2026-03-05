# Travel Booking Microservices

This repository is a Travel Booking rebrand of Google Cloud's microservices demo, kept as a polyglot microservice architecture.

## Overview

- Architecture style: microservices (gRPC + HTTP frontend)
- Runtime targets: Docker Compose (local), Helm + Kubernetes (deployment)
- Languages in services: Go, Java, C#, Python, Node.js
- Data contract: existing `hipstershop` protobuf package is intentionally preserved for compatibility

## Services

Core services in this repo:

- `frontend`
- `productcatalogservice`
- `cartservice`
- `checkoutservice`
- `currencyservice`
- `paymentservice`
- `shippingservice`
- `recommendationservice`
- `emailservice`
- `adservice`
- `redis-cart`
- `loadgenerator` (optional)

Infrastructure/deployment folders:

- `helm/`
- `eksinfra/`
- `oidc-setup/`
- `architecture/`

## Local Run

```bash
docker compose up --build -d
docker compose ps
```

Open: [http://localhost:8080](http://localhost:8080)

## CI/CD (GitHub Actions)

CI/CD is handled by workflows in `.github/workflows/`.

Per-service workflow behavior:

1. Pull Request checks:
- Build
- Test (when configured)
- Security/static checks (service-specific)
- SonarCloud scan

2. Push to `main`:
- Build and push image to GHCR (`ghcr.io/<org>/<service>:<sha>`)
- Run `update-helm` job to open/update Helm values PR via `.github/scripts/update-helm-values-pr.sh`

Infra workflows:

- `eksinfra.yml`: Terraform init/validate/plan/apply/destroy with AWS role assumption
- `oidc-setup.yml`: Terraform workflow for OIDC bootstrap

## Helm

Helm chart: `helm/microservices-chart`

- Chart metadata in `Chart.yaml`
- Default image repositories in `values.yaml`
- Values are updated automatically by CI `update-helm` jobs

## Compatibility Notes

To keep platform stability and CI compatibility:

- gRPC proto package and message names remain unchanged
- Existing HTTP route contracts remain unchanged
- Service names in `docker-compose.yml` remain unchanged

## Source Lineage

Original application source: [GoogleCloudPlatform/microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)
