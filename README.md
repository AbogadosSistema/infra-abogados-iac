# Infra Abogados – Infraestructura como Código

Proyecto de infraestructura como código para un sistema de gestión de audiencias de un bufete de abogados, desarrollado para el curso de Infraestructura como Código.

## Objetivo

Diseñar y desplegar en AWS la arquitectura mostrada en el diagrama oficial del proyecto:
- Frontend estático en S3 + CloudFront.
- Autenticación con Cognito (roles ADMIN, ABOGADO, SECRETARIA).
- API expuesta con API Gateway + WAF.
- Lógica de negocio en AWS Lambda dentro de una VPC privada.
- Almacenamiento de datos en DynamoDB y documentos adjuntos en S3.
- Seguridad con KMS, VPC Endpoints, AWS WAF.
- Observabilidad con CloudWatch, SNS y CloudTrail.
- Backups automáticos con AWS Backup.

## Stack principal

- **Terraform** para declarar y versionar la infraestructura.
- **AWS** como proveedor cloud (us-east-1).
- **GitHub** como repositorio de código y CI/CD (más adelante).

## Estructura inicial del repositorio

> Se creará al clonar el repo en VS Code:

- `terraform/`
  - `modules/` – módulos reutilizables de infraestructura (VPC, Lambdas, DynamoDB, etc.).
  - `envs/`
    - `dev/` – entorno de desarrollo.
    - `prod/` – entorno de producción (opcional para el curso).
- `lambda/` – código fuente de funciones Lambda (MVP sencillo).
- `frontend/` – artefactos del frontend estático (si se agrega).

