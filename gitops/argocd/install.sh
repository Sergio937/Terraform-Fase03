#!/bin/bash
# Script de instalação e configuração do ArgoCD

set -e

echo "=========================================="
echo "  ArgoCD Installation & Setup"
echo "=========================================="
echo ""

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl não encontrado. Instale kubectl primeiro."
    exit 1
fi

# Verificar conexão com cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Não foi possível conectar ao cluster Kubernetes."
    echo "Configure o kubectl com: oci ce cluster create-kubeconfig --cluster-id <id>"
    exit 1
fi

echo "✅ Conectado ao cluster Kubernetes"
echo ""

# 1. Criar namespace argocd
echo "1️⃣  Criando namespace 'argocd'..."
kubectl create namespace argocd 2>/dev/null || echo "   Namespace já existe"
echo ""

# 2. Instalar ArgoCD
echo "2️⃣  Instalando ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "   Aguardando pods do ArgoCD ficarem prontos (isso pode levar alguns minutos)..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

echo "✅ ArgoCD instalado com sucesso!"
echo ""

# 3. Obter senha do admin
echo "3️⃣  Obtendo senha inicial do admin..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "=========================================="
echo "  Credenciais do ArgoCD"
echo "=========================================="
echo "Usuário: admin"
echo "Senha: $ARGOCD_PASSWORD"
echo ""
echo "⚠️  IMPORTANTE: Salve esta senha!"
echo "=========================================="
echo ""

# 4. Perguntar sobre exposição do serviço
echo "4️⃣  Como deseja acessar o ArgoCD?"
echo "   1) Port Forward (desenvolvimento - localhost:8080)"
echo "   2) LoadBalancer (produção - IP externo)"
echo "   3) Pular por enquanto"
echo ""
read -p "Escolha uma opção (1-3): " EXPOSE_OPTION

case $EXPOSE_OPTION in
    1)
        echo ""
        echo "Iniciando port-forward..."
        echo "ArgoCD estará disponível em: https://localhost:8080"
        echo "Use Ctrl+C para parar"
        echo ""
        kubectl port-forward svc/argocd-server -n argocd 8080:443
        ;;
    2)
        echo ""
        echo "Configurando LoadBalancer..."
        kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
        
        echo "Aguardando IP externo..."
        sleep 10
        
        EXTERNAL_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        
        if [ -z "$EXTERNAL_IP" ]; then
            echo "⏳ LoadBalancer ainda está sendo provisionado."
            echo "Execute para verificar: kubectl get svc argocd-server -n argocd"
        else
            echo "✅ ArgoCD disponível em: https://$EXTERNAL_IP"
        fi
        ;;
    3)
        echo "Você pode acessar mais tarde com:"
        echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
        ;;
    *)
        echo "Opção inválida"
        ;;
esac

echo ""
echo "=========================================="
echo "  Próximos Passos"
echo "=========================================="
echo ""
echo "1. Acesse a UI do ArgoCD e faça login"
echo ""
echo "2. Edite as Applications em gitops/apps/ com a URL do seu repositório:"
echo "   sed -i 's|<seu-usuario>/<seu-repo>|seu-usuario/seu-repo|g' gitops/apps/*.yaml"
echo ""
echo "3. Aplique as Applications:"
echo "   kubectl apply -f gitops/apps/"
echo ""
echo "4. Verifique no ArgoCD UI ou com:"
echo "   kubectl get applications -n argocd"
echo ""
echo "=========================================="
echo "  Instalação Concluída! 🎉"
echo "=========================================="
