#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EKS_DIR="$ROOT_DIR/terraform-eks"
JENKINS_DIR="$ROOT_DIR/terraform-jenkins"
AUTO_APPROVE=""
YES="false"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--auto-approve] [--yes]

Destroy order (safe reverse order):
  1) Jenkins EC2 server
  2) EKS infrastructure

Options:
  --auto-approve   Skip Terraform interactive approval prompts
  --yes            Skip final confirmation prompt
  -h, --help       Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-approve)
      AUTO_APPROVE="-auto-approve"
      shift
      ;;
    --yes)
      YES="true"
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

run_tf_destroy() {
  local dir="$1"
  echo ""
  echo "==> Running Terraform destroy in: $dir"
  terraform -chdir="$dir" init
  terraform -chdir="$dir" destroy $AUTO_APPROVE
}

require_cmd terraform

if [[ "$YES" != "true" ]]; then
  read -r -p "This will DESTROY Jenkins and EKS resources. Continue? (yes/no): " answer
  if [[ "$answer" != "yes" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Starting destroy..."
run_tf_destroy "$JENKINS_DIR"
run_tf_destroy "$EKS_DIR"

echo ""
echo "All infrastructure destroyed."
