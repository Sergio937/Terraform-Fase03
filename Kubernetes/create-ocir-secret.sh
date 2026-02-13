#!/bin/bash
# Script para criar o image pull secret do OCIR no Kubernetes

set -e

echo "=== Criação do Image Pull Secret para OCIR ==="
echo ""

# Verificar se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Por favor, instale-o primeiro."
    exit 1
fi

# Verificar se o namespace existe
if ! kubectl get namespace togglemaster &> /dev/null; then
    echo "⚠️  Namespace 'togglemaster' não encontrado."
    read -p "Deseja criar o namespace agora? (s/n): " CREATE_NS
    if [ "$CREATE_NS" = "s" ] || [ "$CREATE_NS" = "S" ]; then
        kubectl create namespace togglemaster
        echo "✅ Namespace criado!"
    else
        echo "❌ Namespace necessário. Execute: kubectl apply -f Kubernetes/namespace/namespace.yaml"
        exit 1
    fi
fi

echo ""
echo "Para criar o secret, você precisa de:"
echo "1. Tenancy Namespace (encontrado em: OCI Console > Governance > Tenancy Details)"
echo "2. Usuário OCI (seu email de login no OCI)"
echo "3. Auth Token (gerado em: OCI Console > User Settings > Auth Tokens)"
echo ""

read -p "Digite o tenancy namespace: " TENANCY_NAMESPACE
read -p "Digite o usuário OCI (ex: oracleidentitycloudservice/seu@email.com): " OCI_USER
read -sp "Digite o Auth Token: " AUTH_TOKEN
echo ""

if [ -z "$TENANCY_NAMESPACE" ] || [ -z "$OCI_USER" ] || [ -z "$AUTH_TOKEN" ]; then
  echo "❌ Todos os campos são obrigatórios!"
  exit 1
fi

# Região do OCIR (pode ser ajustado conforme necessário)
OCIR_REGION="gru.ocir.io"  # São Paulo
# Outras opções:
# - iad.ocir.io (Ashburn)
# - phx.ocir.io (Phoenix)
# - fra.ocir.io (Frankfurt)

echo ""
echo "Criando secret com:"
echo "  Registry: $OCIR_REGION"
echo "  Username: $TENANCY_NAMESPACE/$OCI_USER"
echo "  Namespace: togglemaster"
echo ""

# Criar o secret
kubectl create secret docker-registry ocir-secret \
  --docker-server=$OCIR_REGION \
  --docker-username="$TENANCY_NAMESPACE/$OCI_USER" \
  --docker-password="$AUTH_TOKEN" \
  --namespace=togglemaster

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Secret 'ocir-secret' criado com sucesso no namespace 'togglemaster'!"
    echo ""
    echo "Verifique com:"
    echo "  kubectl get secret ocir-secret -n togglemaster"
    echo ""
    echo "Agora você pode aplicar os deployments dos microsserviços."
else
    echo ""
    echo "❌ Falha ao criar o secret. Verifique as credenciais e tente novamente."
    exit 1
fi
