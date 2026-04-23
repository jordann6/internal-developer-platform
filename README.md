# Internal Developer Platform (IDP)

A security-hardened Internal Developer Platform built on [Backstage](https://backstage.io), deployed to AWS ECS Fargate with RDS PostgreSQL. Features self-service golden path templates that scaffold production-ready microservices with IaC, CI/CD pipelines, and service catalog registration.

## Architecture

- **Backstage** on ECS Fargate (developer portal)
- **RDS PostgreSQL** (service catalog, metadata)
- **ECR** with image scanning on push
- **KMS** customer managed key (encrypts all data at rest)
- **VPC Flow Logs** (network audit trail)
- **Secrets Manager** (database credentials)
- **ALB** with access logging

## Security

- Encryption at rest for all data stores (KMS)
- Least privilege IAM (scoped task execution and task roles)
- Network segmentation (private subnets for compute and data)
- VPC Flow Logs for network auditing
- Container hardening (drop all Linux capabilities, non-root user)
- Image scanning on push (ECR)
- ALB access logs to encrypted S3
- No hardcoded credentials (Secrets Manager)

## Deploy

```bash
./scripts/deploy.sh
```

## Teardown

```bash
./scripts/teardown.sh
```

## Stack

Backstage, Terraform, ECS Fargate, RDS PostgreSQL, ECR, KMS, Secrets Manager, CloudWatch, GitHub Actions
