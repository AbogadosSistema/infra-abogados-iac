#!/usr/bin/env bash
set -euo pipefail

# Primer argumento: entorno (dev, prod, etc.). Por defecto dev.
ENVIRONMENT="${1:-dev}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ROOT_DIR}/terraform/envs/${ENVIRONMENT}"

echo "Entorno: ${ENVIRONMENT}"
echo "Carpeta de trabajo: ${ENV_DIR}"

cd "${ENV_DIR}"

echo "==== terraform init ===="
terraform init -input=false

echo "==== terraform validate ===="
terraform validate

echo "==== terraform plan ===="
terraform plan -input=false -out=tfplan

echo "Terraform plan finalizado correctamente."
