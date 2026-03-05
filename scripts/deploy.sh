#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EKS_DIR="$ROOT_DIR/terraform-eks"
JENKINS_DIR="$ROOT_DIR/terraform-jenkins"
AUTO_APPROVE=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--auto-approve]

Deploy order:
  1) EKS infrastructure
  2) Jenkins EC2 server

Options:
  --auto-approve   Skip Terraform interactive approval prompts
  -h, --help       Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-approve)
      AUTO_APPROVE="-auto-approve"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: '$1' is not installed or not in PATH."
    exit 1
  }
}

run_tf_apply() {
  local dir="$1"
  echo ""
  echo "==> Running Terraform apply in: $dir"
  terraform -chdir="$dir" init
  terraform -chdir="$dir" plan
  terraform -chdir="$dir" apply $AUTO_APPROVE
}

require_cmd terraform
require_cmd aws

if [[ ! -f "$EKS_DIR/terraform.tfvars" || ! -f "$JENKINS_DIR/terraform.tfvars" ]]; then
  echo "Error: terraform.tfvars missing in one of the stack directories."
  exit 1
fi

echo "Starting deployment..."
run_tf_apply "$EKS_DIR"
run_tf_apply "$JENKINS_DIR"

echo ""
echo "==> Deployment completed"

CLUSTER_NAME="$(terraform -chdir="$EKS_DIR" output -raw cluster_name 2>/dev/null || true)"
REGION="$(awk -F '"' '/^region/ {print $2}' "$EKS_DIR/terraform.tfvars" | head -n1)"

if [[ -n "$CLUSTER_NAME" && -n "$REGION" ]]; then
  echo "Configuring kubeconfig for cluster: $CLUSTER_NAME (region: $REGION)"
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
fi

echo ""
echo "EKS outputs:"
terraform -chdir="$EKS_DIR" output || true

echo ""
echo "Jenkins outputs:"
terraform -chdir="$JENKINS_DIR" output || true

echo ""
echo "Next: open Jenkins URL from output and configure credentials: dockerhub, aws-creds"
