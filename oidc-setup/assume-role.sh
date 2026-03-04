#!/bin/bash

ROLE_ARN="${ROLE_ARN:-}"
SESSION_NAME="${SESSION_NAME:-local-eks-session}"
CLUSTER_NAME="${CLUSTER_NAME:-online-boutique-eks}"
REGION="${REGION:-eu-west-2}"

if [ -z "$ROLE_ARN" ]; then
    echo "Missing ROLE_ARN. Example:"
    echo "  ROLE_ARN=arn:aws:iam::<account-id>:role/GitHub-Actions-OIDC-Role ./assume-role.sh"
    exit 1
fi

echo "Assuming role: $ROLE_ARN"
eval $(aws sts assume-role --role-arn "$ROLE_ARN" --role-session-name "$SESSION_NAME" --output json | jq -r '.Credentials | "export AWS_ACCESS_KEY_ID=\(.AccessKeyId) AWS_SECRET_ACCESS_KEY=\(.SecretAccessKey) AWS_SESSION_TOKEN=\(.SessionToken)"')

if [ $? -eq 0 ]; then
    echo "Successfully assumed role"
    echo "Updating kubeconfig..."
    aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
    echo "Ready to use kubectl!"
else
    echo "Failed to assume role"
fi
