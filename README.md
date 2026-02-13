# ToggleMaster - Plataforma de Feature Flags

Plataforma completa de Feature Flags com cinco microsservicos rodando em Amazon EKS, com GitOps via ArgoCD.

## Microsservicos

- Analytics Service (Python) - Porta 8005
- Auth Service (Go) - Porta 8001
- Evaluation Service (Go) - Porta 8004
- Flag Service (Python) - Porta 8002
- Targeting Service (Python) - Porta 8003

## Infraestrutura (AWS)

- EKS (Kubernetes)
- ECR (Container Registry)
- RDS PostgreSQL
- ElastiCache Redis
- DynamoDB
- SQS
- VPC com subnets publicas e privadas

## Comecando rapido

- Guia rapido: QUICKSTART.md
- Deploy detalhado: Kubernetes/DEPLOY.md
- GitOps: gitops/README.md e gitops/GITOPS-GUIDE.md

## Terraform

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edite terraform/terraform.tfvars

make init
make plan
make apply
```

## GitHub Secrets (CI/CD)

Configure em Settings > Secrets and variables > Actions:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
AWS_ACCOUNT_ID
PROJECT_NAME
```

## Fluxo GitOps (resumo)

1. Push na branch main
2. GitHub Actions faz build/test/scan e push para ECR
3. Pipeline atualiza manifest GitOps
4. ArgoCD detecta e sincroniza no EKS

## Desenvolvimento local

```bash
make local-analytics
make local-auth
make local-evaluation
make local-flag
make local-targeting
```

## Comandos utiles

```bash
make argocd-ui
make argocd-status
make pods
make services
make ingress
make logs-analytics
```
