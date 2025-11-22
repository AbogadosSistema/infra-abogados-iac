#!/usr/bin/env bash
# Ejecuta terraform init + plan sobre el entorno dev

set -e

cd terraform/envs/dev

terraform init
terraform plan