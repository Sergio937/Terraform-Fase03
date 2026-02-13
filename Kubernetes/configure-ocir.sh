#!/bin/bash
# Script para configurar os deployments com as informações corretas do OCIR

set -e

echo "=== Configuração dos Deployments para OCIR ==="
echo ""

# Solicitar informações
read -p "Digite o namespace da sua tenancy OCI (ex: grxyz123): " NAMESPACE
read -p "Digite o nome do projeto (usado no Terraform): " PROJECT

if [ -z "$NAMESPACE" ] || [ -z "$PROJECT" ]; then
  echo "Erro: namespace e project são obrigatórios!"
  exit 1
fi

echo ""
echo "Atualizando deployments com:"
echo "  Namespace: $NAMESPACE"
echo "  Project: $PROJECT"
echo ""

# Atualizar todos os deployments
for service in analytics-service auth-service evaluation-service flag-service targeting-service; do
  file="Kubernetes/$service/deployment.yaml"
  if [ -f "$file" ]; then
    echo "Atualizando $file..."
    sed -i "s|<namespace>|$NAMESPACE|g" "$file"
    sed -i "s|<project-name>|$PROJECT|g" "$file"
  else
    echo "⚠️  Arquivo não encontrado: $file"
  fi
done

echo ""
echo "✅ Deployments configurados com sucesso!"
echo ""
echo "Próximos passos:"
echo "1. Crie o image pull secret:"
echo "   kubectl create secret docker-registry ocir-secret \\"
echo "     --docker-server=gru.ocir.io \\"
echo "     --docker-username='$NAMESPACE/<seu-usuario-oci>' \\"
echo "     --docker-password='<seu-auth-token>' \\"
echo "     --namespace=togglemaster"
echo ""
echo "2. Configure os secrets do GitHub Actions:"
echo "   - OCI_AUTH_TOKEN"
echo "   - OCI_USERNAME"
echo "   - OCI_REGISTRY_URL: gru.ocir.io"
echo "   - OCI_NAMESPACE: $NAMESPACE"
echo "   - PROJECT_NAME: $PROJECT"
echo ""
echo "3. Aplique os manifestos seguindo o guia em Kubernetes/DEPLOY.md"
