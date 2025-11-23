#!/usr/bin/env bash
set -euo pipefail

# Ruta al root del repo (carpeta donde está el Jenkinsfile)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}/terraform"

echo "Directorio actual (Terraform root): $(pwd)"
echo "Ejecutando Checkov..."

# Asume que checkov ya está instalado en la máquina Jenkins (pip o docker, como lo tengas)
checkov -d . --quiet

echo "Checkov finalizado correctamente."