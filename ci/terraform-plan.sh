#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
ACTION="${2:-plan}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ROOT_DIR}/terraform/envs/${ENVIRONMENT}"

echo "Entorno: ${ENVIRONMENT}"
echo "Carpeta de trabajo: ${ENV_DIR}"

cd "${ENV_DIR}"

echo "==== terraform init ===="
terraform init -input=false

echo "==== terraform validate ===="
terraform validate

if [[ "${ACTION}" == "plan" ]]; then
  echo "==== terraform plan ===="
  terraform plan -input=false
elif [[ "${ACTION}" == "apply" ]]; then
  echo "==== terraform apply ===="
  terraform apply -input=false -auto-approve
else
  echo "Acción desconocida: ${ACTION}"
  exit 1
fi
