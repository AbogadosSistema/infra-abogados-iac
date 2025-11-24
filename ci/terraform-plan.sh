# ci/terraform-plan.sh
#!/usr/bin/env bash
set -euo pipefail

# Primer argumento: entorno (dev, prod, etc.). Por defecto dev.
ENVIRONMENT="${1:-dev}"

# Directorio raíz del repo (sube desde ci/ a la raíz)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ROOT_DIR}/terraform/envs/${ENVIRONMENT}"

echo "Entorno: ${ENVIRONMENT}"
echo "Carpeta de trabajo: ${ENV_DIR}"

if [ ! -d "${ENV_DIR}" ]; then
  echo "ERROR: el directorio de entorno no existe: ${ENV_DIR}"
  exit 1
fi

cd "${ENV_DIR}"

echo "==== terraform init ===="
terraform init -input=false

echo "==== terraform validate ===="
terraform validate

echo "==== terraform plan ===="

if [ -f "terraform.tfvars" ]; then
  echo "Usando terraform.tfvars para el entorno ${ENVIRONMENT}"
  terraform plan -input=false -out=tfplan -var-file="terraform.tfvars"
else
  echo "ATENCIÓN: no se encontró terraform.tfvars en ${ENV_DIR}"
  echo "Ejecutando terraform plan sin var-file (usará defaults/variables de CLI/entorno)..."
  terraform plan -input=false -out=tfplan
fi

echo "Terraform plan finalizado correctamente."
