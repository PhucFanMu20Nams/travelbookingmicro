# Microservices Helm Chart

This Helm chart deploys a microservices application (Online Boutique demo) to Kubernetes.

## Chart Generation

This chart was generated from existing Kubernetes manifests using the following approach:

```bash
# Create basic chart structure
helm create microservices-chart

# Or manually create directories
mkdir microservices-chart
mkdir microservices-chart/charts
mkdir microservices-chart/templates
```

Then the templates were created by converting the original Kubernetes manifests to Helm templates:

1. **Extract configurable values** - Identify hardcoded values (images, ports, resources) and move them to `values.yaml`
```bash
# Analyze manifests for common patterns
grep -r "image:" kubernetes-manifests/
grep -r "port:" kubernetes-manifests/
```

2. **Replace with template variables** - Convert static values to Helm template syntax
```bash
# Example: Replace hardcoded image names
# From: image: frontend
# To: image: {{ .Values.services.frontend.image }}
```

3. **Validate templates** - Test the chart syntax and rendering
```bash
helm template microservices-chart --debug
helm lint microservices-chart
```

4. **Test installation** - Verify the chart works
```bash
helm install test-release microservices-chart --dry-run
```

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- Container images built and available in your registry

## Installation

1. Install the chart:
```bash
helm install my-microservices ./microservices-chart
```

2. Install with custom values:
```bash
helm install my-microservices ./microservices-chart -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `services.frontend.serviceType` | Frontend service type | `LoadBalancer` |
| `services.*.image` | Container image for each service | Service name |
| `services.*.resources` | Resource requests/limits | See values.yaml |
| `redis.image` | Redis image | `redis:alpine` |
| `securityContext` | Pod security context | See values.yaml |

## Services

The chart deploys the following services:
- **frontend** - Web UI (exposed via LoadBalancer)
- **adservice** - Advertisement service
- **cartservice** - Shopping cart service
- **checkoutservice** - Checkout service
- **currencyservice** - Currency conversion service
- **emailservice** - Email service
- **paymentservice** - Payment processing service
- **productcatalogservice** - Product catalog service
- **recommendationservice** - Product recommendation service
- **shippingservice** - Shipping service
- **loadgenerator** - Load testing service
- **redis-cart** - Redis cache for cart service

## Accessing the Application

After installation, get the frontend service URL:
```bash
kubectl get service frontend-external
```

## Uninstallation

```bash
helm uninstall my-microservices
```