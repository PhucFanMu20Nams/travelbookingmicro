#!/bin/bash

# Health check script for ALB controller and ingress
NAMESPACE="kube-system"
MONITORING_NS="monitoring"
CLUSTER_NAME="online-boutique-eks"
REGION="eu-west-2"

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "Verifying cluster connection..."
kubectl cluster-info

echo "Checking ALB Controller pods..."
kubectl get pods -l app.kubernetes.io/name=aws-load-balancer-controller -n $NAMESPACE

echo "Waiting for ALB Controller to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=aws-load-balancer-controller -n $NAMESPACE --timeout=300s || echo "ALB Controller not ready, continuing..."

echo "Checking webhook service endpoints..."
kubectl get endpoints aws-load-balancer-webhook-service -n $NAMESPACE || echo "Webhook service not found"

echo "Checking Grafana pods..."
kubectl get pods -l app.kubernetes.io/name=grafana -n $MONITORING_NS

echo "Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n $MONITORING_NS --timeout=300s || echo "Grafana not ready, continuing..."

echo "Verifying ingress creation..."
kubectl get ingress -n $MONITORING_NS || echo "No ingress found"

echo "Health check completed!"