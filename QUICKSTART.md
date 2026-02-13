# Quick Start Guide

Guia rapido para colocar a plataforma ToggleMaster em producao na AWS.

## Pre-requisitos

- Conta AWS
- Terraform instalado (v1.0+)
- kubectl instalado
- Git configurado
- Repositorio no GitHub

## Fluxo completo

### 1) Configuracao inicial

```bash
# Clone o repositorio
git clone <seu-repo>
cd Terraform-Fase03

# Configure as variaveis do Terraform
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edite terraform/terraform.tfvars com seus valores AWS

# Configure as variaveis de ambiente para ECR
cp .env.example .env
# Edite .env com suas credenciais AWS
```

### 2) Provisionar infraestrutura

```bash
make init
make plan
make apply

# Salve os outputs importantes
make tf-output > infrastructure-outputs.txt
```

### 3) Configurar GitHub Secrets

Em GitHub: Settings > Secrets and variables > Actions

```
AWS_ACCESS_KEY_ID     = <seu-access-key-id>
AWS_SECRET_ACCESS_KEY = <seu-secret-access-key>
AWS_REGION            = us-east-1
AWS_ACCOUNT_ID        = <sua-conta-aws>
PROJECT_NAME          = <nome-do-projeto>
```

### 4) Configurar Kubernetes

```bash
# Configure kubectl para o cluster EKS
aws eks update-kubeconfig \
  --name <cluster-name-do-terraform-output> \
  --region us-east-1

# Crie o namespace
make create-namespace

# (Opcional) Crie o secret de pull do ECR
make create-secret

# Preencha endpoints/imagens com outputs do Terraform
make configure-endpoints
```

### 5) Instalar ArgoCD e configurar GitOps

```bash
make install-argocd
make configure-argocd-apps
make apply-argocd-apps

# Envie o estado inicial para o GitHub
git add .
git commit -m "Initial deployment"
git push origin main
```

### 6) Verificar deploy

```bash
make argocd-status
make pods
make ingress
```

## Endpoints da API

Depois do deploy, use o IP do Ingress:

```
http://<INGRESS-IP>/auth/health
http://<INGRESS-IP>/flags/health
http://<INGRESS-IP>/targeting/health
http://<INGRESS-IP>/evaluate/health
http://<INGRESS-IP>/analytics/health
```

## Comandos uteis

```bash
make argocd-ui
make argocd-password
make logs-analytics
make logs-auth
make logs-evaluation
make logs-flag
make logs-targeting
```

## Troubleshooting rapido

```bash
make events
kubectl describe pod <pod-name> -n togglemaster
kubectl logs <pod-name> -n togglemaster
```
