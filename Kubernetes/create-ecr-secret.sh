#!/bin/bash
# Script opcional para criar image pull secret do ECR

set -e

echo "=== Image Pull Secret (ECR) ==="
echo ""
echo "Observacao: em EKS, o acesso ao ECR normalmente funciona via IAM do node."
echo "Se voce quiser usar secret de pull, preencha os dados abaixo."
echo ""

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Erro: kubectl nao encontrado."
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "Erro: aws CLI nao encontrado."
  exit 1
fi

read -p "Deseja criar o secret agora? (s/n): " CREATE
if [ "$CREATE" != "s" ] && [ "$CREATE" != "S" ]; then
  echo "Ok, secret nao sera criado."
  exit 0
fi

read -p "AWS Account ID: " AWS_ACCOUNT_ID
read -p "AWS Region (ex: us-east-1): " AWS_REGION
read -p "Namespace do Kubernetes (default: togglemaster): " K8S_NAMESPACE
K8S_NAMESPACE=${K8S_NAMESPACE:-togglemaster}

if [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$AWS_REGION" ]; then
  echo "Erro: account id e region sao obrigatorios."
  exit 1
fi

aws ecr get-login-password --region "$AWS_REGION" | \
  kubectl create secret docker-registry ecr-secret \
    --docker-server="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com" \
    --docker-username=AWS \
    --docker-password-stdin \
    --namespace="$K8S_NAMESPACE"

echo ""
echo "✅ Secret 'ecr-secret' criado no namespace $K8S_NAMESPACE."
