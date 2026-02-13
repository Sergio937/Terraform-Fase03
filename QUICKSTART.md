# 🚀 Quick Start Guide

Guia rápido para colocar a plataforma ToggleMaster em produção.

## Pré-requisitos

- ✅ Conta Oracle Cloud Infrastructure (OCI)
- ✅ Terraform instalado (v1.0+)
- ✅ kubectl instalado
- ✅ Git configurado
- ✅ GitHub repository criado

## Fluxo Completo (40 minutos)

### 1️⃣ Configuração Inicial (5 min)

```bash
# Clone o repositório
git clone <seu-repo>
cd Terraform-novo

# Configure as variáveis do Terraform
cp envs/dev.tfvars.example envs/dev.tfvars
# Edite envs/dev.tfvars com seus valores OCI

# Configure as variáveis de ambiente
cp .env.example .env
# Edite .env com suas credenciais OCI
```

### 2️⃣ Provisionar Infraestrutura (15 min)

```bash
# Inicializar e aplicar Terraform
make init
make plan
make apply

# Aguarde a criação do cluster OKE, bancos, redis, etc.
# Salve os outputs importantes
make tf-output > infrastructure-outputs.txt
```

### 3️⃣ Configurar GitHub Secrets (2 min)

Vá em: **GitHub > Settings > Secrets and variables > Actions** e adicione:

```
OCI_AUTH_TOKEN       = <seu-auth-token>
OCI_USERNAME         = <namespace>/<seu-usuario>
OCI_REGISTRY_URL     = gru.ocir.io
OCI_NAMESPACE        = <seu-tenancy-namespace>
PROJECT_NAME         = togglemaster
```

### 4️⃣ Configurar Kubernetes & ArgoCD (10 min)

```bash
# Configurar kubectl para o cluster OKE
oci ce cluster create-kubeconfig \
  --cluster-id <cluster-id-do-terraform-output> \
  --file $HOME/.kube/config \
  --region sa-saopaulo-1

# Criar namespace
make create-namespace

# Criar secret para pull de imagens
make create-secret
# Siga as instruções interativas

# Configurar deployments com URLs corretas
make configure-deployments

# Instalar ArgoCD
make install-argocd
# Salve a senha exibida!

# Configurar ArgoCD Applications E atualizar GitOps)
git add .
git commit -m "Initial deployment"
git push origin main

# Aguarde os workflows completarem (~5-10 min)
# Verifique em: GitHub > Actions

# ArgoCD vai detectar as mudanças e fazer deploy automaticamente!
# Acompanhe em tempo real:
make argocd-ui
# Acesse: https://localhost:8080
# User: admin, Password: (exibida no passo 4)
# Push para GitHub (CI/CD vai buildar as imagens)
git add .
git commit -m "Initial deployment"
git push origin main

# Aguarde os workflows completarem (~5-10 min)
# Verifique em: GitHub > Actions

# Quando os workflows terminarem, faça deploy no K8s
make deploy-all
```

### 6️⃣ Verificar Deploy

```bash
# Ver status no ArgoCD
make argocd-status

# Ver pods
make pods

# Ver ingress (obtenha o IP externo)
make ingress

# Ver logs de um serviço específico
make logs-analytics

# Acessar ArgoCD UI
make argocd-ui
make logs-evaluation
make logs-flag
make logs-targeting
```

## 🎯 Endpoints da API

Após o deploy, acesse via IP do Ingress:

```
http://<INGRESS-IP>/auth/health       # Auth Service
http://<INGRESS-IP>/flags/health      # Flag Service
http://<INGRESS-IP>/targeting/health  # Targeting Service
http://<INGRESS-IP>/evaluate/health   # Evaluation Service
http://<INGRESS-IP>/ana (GitOps):

```bash
# 1. Crie uma branch
git checkout -b feature/nova-feature

# 2. Faça suas alterações no código

# 3. Push para GitHub (CI/CD vai rodar em PR)
git push origin feature/nova-feature

# 4. Abra Pull Request
# Os workflows vão rodar automaticamente:
# - Build & Tests
# - Linting
# - Security Scans

# 5. Merge para main
# Workflow vai:
# - Buildar e pushar imagem para OCIR
# - Atualizar manifest GitOps com nova tag
# - ArgoCD detecta e faz deploy automaticamente

# 6. Acompanhe o deploy no ArgoCD UI
make argocd-ui
# Você verá o serviço ficando "Syncing" → "Synced & Healthy"

# 6. Atualize o deployment no Kubernetes
make restart-<service-name>
# ou
kubectl rollout restart deployment/<service-name> -n togglemaster
```
argocd-status       # Status no ArgoCD
make argocd-ui           # Abrir UI do ArgoCD
make pods                # Ver pods
make services            # Ver services
make events              # Ver eventos recentes
make logs-<service>      # Logs de um serviço
```

### GitOps & ArgoCD

```bash
make argocd-password     # Ver senha do ArgoCD
make argocd-ui           # Abrir UI (localhost:8080)
make argocd-status       # Status das applications
make argocd-sync-all     # Forçar sync (requer CLI)

```bash
make status              # Status geral
make pods                # Ver pods
make services            # Ver services
make events              # Ver eventos recentes
make logs-<service>      # Logs de um serviço
```

### Rollout e Restart

```bash
make restart-all         # Reinicia todos os deployments
make restart-<service>   # Reinicia um serviço específico
make rollout-status DEPLOY=auth-service  # Status do rollout
```

### Port Forwarding (teste local)

```bash
make port-forward-auth        # localhost:8001
make port-forward-flag        # localhost:8002
make port-forward-targeting   # localhost:8003
make port-forward-evaluation  # localhost:8004
make port-forward-analytics   # localhost:8005
```

### Debug

- ✅ GitOps implementado (ArgoCD)
- ✅ Senha do ArgoCD alterada (após primeiro login)
```bash
make shell-<service>          # Abre shell no pod
make describe-pod POD=<name>  # Descreve um pod
kubectl get events -n togglemaster --watch  # Eventos em tempo real
```

## 🛡️ Security Checklist

- ✅ Secrets configurados no GitHub (nunca no código)
- ✅ Image pull secret criado no Kubernetes
- ✅ Auth tokens com permissões mínimas
- ✅ Network policies aplicadas
- ✅ Resource limits definidos nos deployments
- ✅ HTTPS configurado no Ingress (configure certificado SSL)
- ✅ Security scans rodando em CI/CD

## 🔧 Troubleshooting

### Pods não iniciam

```bash
# Ver detalhes do pod
kubectl describe pod <pod-name> -n togglemaster

# Ver logs
kubectl logs <pod-name> -n togglemaster

# Verificar events
make events
```

### Problemas com imagens

```bash
# Verificar se o secret está correto
kubectl get secret ocir-secret -n togglemaster -o yaml

# Testar pull manual
docker pull gru.ocir.io/<namespace>/<project>/<service>:latest
```

### CI/CD falhando

1. Verifique se todos os secrets do GitHub estão configurados
2. Veja os logs detalhados em GitHub Actions
3. gitops/GITOPS-GUIDE.md](gitops/GITOPS-GUIDE.md) - Guia completo GitOps
- [gitops/ARGOCD-UI.md](gitops/ARGOCD-UI.md) - Interface do ArgoCD
- [gitops/IMPLEMENTATION-SUMMARY.md](gitops/IMPLEMENTATION-SUMMARY.md) - Resumo da implementação
- [Verifique credenciais OCI
4. Confirme que os repositórios OCIR foram criados pelo Terraform

### Ingress sem IP externo

```bash
# Verificar load balancer
kubectl get svc -n ingress-nginx

# Instalar NGINX Ingress Controller se necessário
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```
as 5 applications no ArgoCD estão `Synced & Healthy`:

```bash
# Verificar pods
kubectl get pods -n togglemaster

# Verificar ArgoCD
make argocd-status

# Testar health checks
curl http://<INGRESS-IP>/auth/health
# Response: {"status":"healthy"}
```

**Sua plataforma GitOps está no ar!** 🚀

### 🎯 Teste o Fluxo GitOps

```bash
# 1. Faça uma mudança pequena em um serviço
echo "# GitOps test" >> Kubernetes/analytics-service/analytics-service/README.md

# 2. Commit e push
git add .
git commit -m "Test GitOps flow"
git push origin main

# 3. Acompanhe no ArgoCD UI
make argocd-ui

# 4. Veja o ArgoCD detectar, sincronizar e fazer deploy automaticamente!
```

Em caso de problemas:

1. Verifique os logs: `make logs-<service>`
2. Verifique eventos: `make events`
3. Consulte a documentação do OCI
4. Revise os workflows do GitHub Actions

## 🎉 Sucesso!

Se todos os pods estão `Running` e os health checks retornam 200:

```bash
curl http://<INGRESS-IP>/auth/health
# Response: {"status":"healthy"}
```

Sua plataforma está no ar! 🚀
