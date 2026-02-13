# GitOps com ArgoCD - Guia Completo

## 📚 O que é GitOps?

GitOps é uma metodologia onde o **Git é a única fonte da verdade** para infraestrutura e aplicações. Todas as mudanças passam pelo Git, e ferramentas automatizadas (como ArgoCD) sincronizam o estado desejado (Git) com o estado real (Kubernetes).

### Benefícios

✅ **Auditoria completa**: Todo deploy tem histórico no Git  
✅ **Rollback fácil**: `git revert` para voltar versão  
✅ **Declarativo**: Manifests descrevem o estado desejado  
✅ **Automação**: Deploy acontece automaticamente  
✅ **Visibilidade**: UI do ArgoCD mostra status em tempo real  
✅ **Segurança**: Não precisa dar acesso direto ao cluster para devs  

## 🏗️ Arquitetura do Fluxo

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│   Developer │─────▶│ GitHub Repo  │◀─────│   ArgoCD    │
│             │ push │              │ pull │             │
└─────────────┘      └──────────────┘      └─────────────┘
                            │                      │
                            │                      │ sync
                            │                      ▼
                     ┌──────▼──────────┐    ┌─────────────┐
                     │  GitHub Actions │    │ EKS Cluster │
                     │   (CI Pipeline) │    │             │
                     └─────────────────┘    └─────────────┘
                            │
                            │ update image tag
                            │
                     ┌──────▼──────────┐
                     │ GitOps Manifests│
                     │  (in Git repo)  │
                     └─────────────────┘
```

### Fluxo Detalhado

1. **Developer faz push** → código fonte no GitHub
2. **GitHub Actions (CI)** → Build, Test, Security Scan, Push image para ECR
3. **CI atualiza GitOps** → Commit com nova tag de imagem nos manifests em `gitops/`
4. **ArgoCD detecta mudança** → Monitora repositório Git
5. **ArgoCD sincroniza** → Aplica mudanças no cluster EKS automaticamente
6. **Deploy concluído** → Nova versão rodando no cluster

## 🚀 Setup Rápido

### 1. Instalar ArgoCD

```bash
# Opção A: Script automatizado
./gitops/argocd/install.sh

# Opção B: Manual
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Obter Credenciais

```bash
# Usuário: admin
# Senha:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```

### 3. Acessar UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Acesse: https://localhost:8080
```

### 4. Configurar Applications

```bash
# Atualizar com URL do seu repo
./gitops/configure-apps.sh

# Aplicar applications
kubectl apply -f gitops/apps/
```

## 📂 Estrutura do Repositório GitOps

```
gitops/
├── README.md                          # Este arquivo
├── argocd/
│   ├── install.sh                     # Script de instalação
│   └── README.md                      # Guia do ArgoCD
├── apps/                              # ArgoCD Applications
│   ├── analytics-service.yaml         # App do Analytics
│   ├── auth-service.yaml              # App do Auth
│   ├── evaluation-service.yaml        # App do Evaluation
│   ├── flag-service.yaml              # App do Flag
│   └── targeting-service.yaml         # App do Targeting
└── manifests/                         # Manifestos K8s
    ├── analytics-service/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   ├── secret.yaml
    │   └── hpa.yaml
    ├── auth-service/
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── configmap.yaml
    │   ├── secret.yaml
    │   └── db/
    │       ├── configmap.yaml
    │       ├── secret.yaml
    │       └── job.yaml
    ├── evaluation-service/
    ├── flag-service/
    ├── targeting-service/
    ├── namespace/
    │   └── namespace.yaml
    └── ingress/
        └── ingress.yaml
```

## 🔄 Workflow de Deploy

### Deploy Automático (Padrão)

Configurado no ArgoCD com `automated: true`:

```yaml
syncPolicy:
  automated:
    prune: true      # Remove recursos deletados do Git
    selfHeal: true   # Reverte mudanças manuais no cluster
```

**Fluxo:**
1. Push no código → CI builda imagem → CI atualiza tag no GitOps manifest
2. ArgoCD detecta mudança (a cada 3 minutos por padrão)
3. ArgoCD sincroniza automaticamente
4. Deploy concluído ✅

### Deploy Manual

Se preferir aprovar deploys manualmente, remova `automated:` das Applications.

```bash
# Ver status
argocd app get analytics-service

# Ver diff antes de aplicar
argocd app diff analytics-service

# Sincronizar manualmente
argocd app sync analytics-service

# Rollback
argocd app rollback analytics-service
```

## 🛠️ ArgoCD CLI

### Instalação

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

### Comandos Úteis

```bash
# Login
ARGOCD_SERVER=localhost:8080  # ou IP do LoadBalancer
argocd login $ARGOCD_SERVER --username admin --password <senha>

# Listar apps
argocd app list

# Status de uma app
argocd app get analytics-service

# Logs
argocd app logs analytics-service

# Histórico
argocd app history analytics-service

# Sincronizar
argocd app sync analytics-service

# Sync automático
argocd app set analytics-service --sync-policy automated

# Deletar app
argocd app delete analytics-service
```

## 🎯 Interface Web do ArgoCD

### Dashboard Principal

Mostra todas as aplicações:
- 🟢 **Synced & Healthy**: App em sincronia com Git e rodando
- 🟡 **OutOfSync**: Git tem mudanças não aplicadas
- 🔴 **Degraded**: Pods com problema
- 🔵 **Progressing**: Deploy em andamento

### Visualização de Aplicação

Clique em uma aplicação para ver:
- **App Details**: YAML da Application
- **Resources Tree**: Diagrama visual dos recursos K8s
- **Events**: Últimos eventos
- **Logs**: Logs dos pods
- **Manifest**: Manifests renderizados

### Sync Options

- **Sync**: Aplicar mudanças do Git
- **Refresh**: Re-fetch do Git
- **Hard Refresh**: Limpar cache
- **Sync Options**: Prune, Force, Dry Run, etc.

## 🔐 Segurança

### RBAC no ArgoCD

```bash
# Criar usuário read-only
argocd account update-password --account <user> --new-password <pwd>

# Ver roles
argocd account list
```

### Secrets no Git

⚠️ **NUNCA** commite secrets em texto plano!

**Opções:**
1. **Sealed Secrets**: Encripta secrets para versionar no Git
2. **External Secrets**: Integra com vault externo (AWS Secrets Manager)
3. **Git-crypt**: Encripta arquivos no Git

## 📊 Monitoramento

### Metrics & Health

ArgoCD monitora:
- ✅ Deployment status
- ✅ Pod health
- ✅ Service endpoints
- ✅ Sync status

### Notifications

Configure notificações para:
- Slack
- Email
- Webhook
- Microsoft Teams

```bash
# Instalar argocd-notifications
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-notifications/stable/manifests/install.yaml
```

## 🔄 Rollback

### Via Git

```bash
# Ver histórico
git log --oneline gitops/manifests/analytics-service/deployment.yaml

# Reverter último commit
git revert HEAD
git push origin main

# ArgoCD vai detectar e aplicar a versão antiga
```

### Via ArgoCD UI

1. Acesse a aplicação
2. Clique em "History and Rollback"
3. Selecione a versão desejada
4. Clique em "Rollback"

### Via CLI

```bash
# Ver histórico
argocd app history analytics-service

# Rollback para revisão específica
argocd app rollback analytics-service <revision-id>
```

## 🐛 Troubleshooting

### App OutOfSync

```bash
# Ver diferenças
argocd app diff analytics-service

# Forçar sync
argocd app sync analytics-service --force
```

### App Degraded

```bash
# Ver recursos com problema
kubectl get all -n togglemaster

# Ver eventos
argocd app get analytics-service --show-operation

# Ver logs
argocd app logs analytics-service --tail 100
```

### Sync Loop

Se ArgoCD fica em loop de sync:
1. Verifique se há processos externos modificando recursos
2. Desabilite `selfHeal` temporariamente
3. Use `IgnoreExtraneous` para recursos gerenciados externamente

## 📈 Melhores Práticas

### 1. Estrutura do Repositório

✅ **Separar ambientes**:
```
gitops/
  ├── base/           # Recursos comuns
  ├── overlays/
      ├── dev/
      ├── staging/
      └── prod/
```

### 2. Sync Policy

✅ **Produção**: Sync manual com aprovação  
✅ **Staging**: Auto-sync com validação  
✅ **Dev**: Auto-sync completo  

### 3. Health Checks

✅ Configure `readinessProbe` e `livenessProbe` em todos os pods  
✅ ArgoCD usa isso para determinar health  

### 4. Resource Hooks

Use hooks para:
- Pre-sync: Backup de dados
- Sync: Migration jobs
- Post-sync: Smoke tests

```yaml
metadata:
  annotations:
    argocd.argoproj.io/hook: PreSync
```

### 5. Imagens com Tags Específicas

❌ **Evite**: `image: service:latest`  
✅ **Use**: `image: service:a1b2c3d` (commit SHA)  

## 🎓 Recursos Adicionais

- [ArgoCD Docs](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

## ✅ Checklist de Setup

- [ ] ArgoCD instalado no cluster
- [ ] Applications configuradas com URL do repo
- [ ] Applications aplicadas (`kubectl apply -f gitops/apps/`)
- [ ] CI/CD atualiza manifestos GitOps (workflows configurados)
- [ ] Secrets do GitHub configurados
- [ ] Namespace `togglemaster` criado
- [ ] Image pull secret `ecr-secret` criado (se necessario)
- [ ] ArgoCD UI acessível
- [ ] Todas as 5 apps aparecem no ArgoCD
- [ ] Apps estão Synced & Healthy
- [ ] Teste de deploy: alterar código → push → verificar sync automático

## 🎉 Pronto!

Agora você tem um pipeline GitOps completo:
- **CI** (GitHub Actions): Build, Test, Security
- **CD** (ArgoCD): Deploy automatizado
- **Single Source of Truth**: Git
- **Visibilidade**: ArgoCD UI
- **Auditoria**: Git history
- **Rollback**: git revert
