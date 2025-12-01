#!/usr/bin/env bash
set -euo pipefail

# Primer argumento: entorno (dev, prod, etc.). Por defecto dev.
ENVIRONMENT="${1:-dev}"

# Segundo argumento: acción (plan | apply). Por defecto "plan".
ACTION="${2:-plan}"

# Directorio raíz del repo (sube desde ci/ a la raíz)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_DIR="${ROOT_DIR}/terraform/envs/${ENVIRONMENT}"

echo "Entorno: ${ENVIRONMENT}"
echo "Acción:  ${ACTION}"
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

TFVARS_ARG=()
if [ -f "terraform.tfvars" ]; then
  echo "Usando terraform.tfvars para el entorno ${ENVIRONMENT}"
  TFVARS_ARG=(-var-file="terraform.tfvars")
else
  echo "ATENCIÓN: no se encontró terraform.tfvars en ${ENV_DIR}"
  echo "Se ejecutará Terraform usando solo variables por defecto / entorno."
fi

case "${ACTION}" in
  plan)
    echo "==== terraform plan (generando tfplan) ===="
    terraform plan -input=false -out=tfplan "${TFVARS_ARG[@]}"
    echo "Plan generado: tfplan"
    ;;

  apply)
    if [ -f tfplan ]; then
      echo "Se encontró tfplan existente. Aplicando ese plan..."
      terraform apply -input=false tfplan
    else
      echo "No existe tfplan. Generando plan rápido antes del apply..."
      terraform plan -input=false -out=tfplan "${TFVARS_ARG[@]}"
      terraform apply -input=false tfplan
    fi
    echo "Terraform apply finalizado correctamente."
    ;;

  *)
    echo "Acción no reconocida: ${ACTION}. Usa 'plan' o 'apply'."
    exit 1
    ;;
esac
