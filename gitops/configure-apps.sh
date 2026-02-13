#!/bin/bash
# Script para atualizar a URL do repositório nas Applications do ArgoCD

set -e

echo "=========================================="
echo "  Configurar ArgoCD Applications"
echo "=========================================="
echo ""

read -p "Digite seu usuário/organização do GitHub: " GITHUB_USER
read -p "Digite o nome do repositório: " GITHUB_REPO

if [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_REPO" ]; then
  echo "❌ Usuário e repositório são obrigatórios!"
  exit 1
fi

REPO_URL="https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git"

echo ""
echo "Atualizando Applications com:"
echo "  Repository: $REPO_URL"
echo ""

# Atualizar todas as applications
for app in gitops/apps/*.yaml; do
  if [ -f "$app" ]; then
    echo "Atualizando $(basename $app)..."
    sed -i "s|repoURL: https://github.com/<seu-usuario>/<seu-repo>.git|repoURL: $REPO_URL|g" "$app"
  fi
done

echo ""
echo "✅ Applications configuradas!"
echo ""
echo "Agora aplique as Applications:"
echo "  kubectl apply -f gitops/apps/"
echo ""
echo "Ou faça commit e push para o repositório:"
echo "  git add gitops/apps/"
echo "  git commit -m 'Configure ArgoCD Applications'"
echo "  git push origin main"
