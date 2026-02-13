# ToggleMaster - Plataforma de Feature Flags

Plataforma completa de Feature Flags com 5 microsserviços rodando em Oracle Kubernetes Engine (OKE).

## 📋 Arquitetura

### Microsserviços

1. **Analytics Service** (Python) - Porta 8005
   - Processa eventos de analytics via SQS
   - Armazena dados em NoSQL (OCI NoSQL)

2. **Auth Service** (Go) - Porta 8001
   - Autenticação e autorização
   - Gerenciamento de usuários
   - PostgreSQL como banco de dados

3. **Evaluation Service** (Go) - Porta 8004
   - Avalia feature flags em tempo real
   - Cache com Redis
   - Integra com Flag e Targeting Services
   - Publica eventos no SQS

4. **Flag Service** (Python) - Porta 8002
   - CRUD de feature flags
   - PostgreSQL como banco de dados

5. **Targeting Service** (Python) - Porta 8003
   - Gerenciamento de regras de targeting
   - PostgreSQL como banco de dados

### Infraestrutura (OCI)

- **Kubernetes**: OKE (Oracle Kubernetes Engine)
- **Container Registry**: OCIR (Oracle Cloud Infrastructure Registry)
- **Bancos de Dados**: PostgreSQL (OCI Database)
- **Cache**: Redis Cluster
- **NoSQL**: OCI NoSQL Database
- **Mensageria**: OCI Queue Service
- **Networking**: VCN com subnets públicas e privadas

## 🚀 CI/CD Pipeline

Cada microsserviço possui um workflow GitHub Actions completo com **GitOps via ArgoCD**:

### Jobs do Pipeline (CI - Continuous Integration)

1. **Build & Test**
   - Compilação do código
   - Execução de testes unitários
   - Build da imagem Docker

2. **Lint & Static Analysis**
   - Python: flake8
   - Go: golangci-lint

3. **Security Scans**
   - **SAST** (Static Analysis): bandit (Python) / gosec (Go)
   - **SCA** (Dependency Scan): Trivy em modo filesystem
   - **Container Scan**: Trivy em imagem Docker
   - ⚠️ Pipeline **falha** se vulnerabilidade CRITICAL é encontrada

4. **Docker Build & Push** (apenas em push na main)
   - Build da imagem Docker
   - Scan de vulnerabilidades da imagem com Trivy
   - Push para OCIR com tags:
     - `<commit-sha>`: primeiros 7 caracteres do commit
     - `latest`: sempre a última versão da main
   - **Atualização GitOps**: Commit automático da nova tag no repositório GitOps

### CD - Continuous Deployment (GitOps com ArgoCD)

- **ArgoCD monitora** o repositório Git em `gitops/manifests/`
- **Sincronização automática** quando detecta mudanças
- **Self-healing**: reverte mudanças manuais não autorizadas
- **Rollback fácil**: via UI ou `git revert`
- **Auditoria completa**: todo deploy registrado no Git

### Fluxo Completo

```
Developer → Git Push → GitHub Actions (CI) → OCIR + GitOps Update
                                                      ↓
                                            ArgoCD detecta mudança
                                                      ↓
                                            Deploy automático no OKE
```

### Workflows

- [.github/workflows/analytics-service.yml](.github/workflows/analytics-service.yml)
- [.github/workflows/auth-service.yml](.github/workflows/auth-service.yml)
- [.github/workflows/evaluation-service.yml](.github/workflows/evaluation-service.yml)
- [.github/workflows/flag-service.yml](.github/workflows/flag-service.yml)
- [.github/workflows/targeting-service.yml](.github/workflows/targeting-service.yml)

### Secrets Necessários no GitHub

Configure estes secrets no repositório GitHub:

```bash
OCI_AUTH_TOKEN          # Auth token gerado no OCI
OCI_USERNAME            # <tenancy-namespace>/<oci-username>
OCI_REGISTRY_URL        # gru.ocir.io
OCI_NAMESPACE           # namespace da tenancy OCI
PROJECT_NAME            # nome do projeto (ex: togglemaster)
```

## 📦 Deploy

### 1. Provisionar Infraestrutura

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Configurar Kubernetes

```bash
# Configurar acesso ao cluster OKE
oci ce cluster create-kubeconfig --cluster-id <cluster-id>

# Executar script de configuração
cd ../Kubernetes
./configure-ocir.sh

# Seguir os passos detalhados
cat DEPLOY.md
```

### 3. Instalar ArgoCD (GitOps)

```bash
# Instalar ArgoCD
make install-argocd

# Configurar Applications
make configure-argocd-apps

# Aplicar Applications
make apply-argocd-apps

# Ver guia completo
cat gitops/GITOPS-GUIDE.md
```

### 4. Fazer Push do Código

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

Os workflows do GitHub Actions irão automaticamente:
- Rodar os testes e security scans
- Fazer build das imagens
- Enviar para o OCIR
- **Atualizar manifests GitOps**

### 5. ArgoCD Sincroniza Automaticamente

ArgoCD detectará as mudanças no repositório e fará o deploy automaticamente no cluster!

## 🔧 Desenvolvimento Local

### Analytics Service (Python)
```bash
cd Kubernetes/analytics-service/analytics-service
pip install -r requirements.txt
python app.py
```

### Auth Service (Go)
```bash
cd Kubernetes/auth-service/auth-service
go mod download
go run main.go
```

### Evaluation Service (Go)
```bash
cd Kubernetes/evaluation-service/evaluation-service
go mod download
go run main.go
```

### Flag Service (Python)
```bash
cd Kubernetes/flag-service/flag-service
pip install -r requirements.txt
python app.py
```

### Targeting Service (Python)
```bash
cd Kubernetes/targeting-service/targeting-service
pip install -r requirements.txt
python app.py
```

## 🛡️ Security

### Políticas de Segurança

- ✅ SAST em todos os PRs e pushes
- ✅ SCA de dependências
- ✅ Scan de imagens Docker
- ✅ Bloqueio em vulnerabilidades CRITICAL
- ✅ Secrets não versionados no código
- ✅ Network policies no Kubernetes
- ✅ Resource limits definidos

### Ferramentas Utilizadas

- **Trivy**: Scan de vulnerabilidades (SCA + Container)
- **Bandit**: SAST para Python
- **gosec**: SAST para Go
- **flake8**: Linting Python
- **golangci-lint**: Linting Go

## 📊 Monitoramento

### Health Checks

Todos os serviços expõem endpoint `/health`:

```bash
# Analytics
curl http://analytics-service:8005/health

# Auth
curl http://auth-service:8001/health

# Evaluation
curl http://evaluation-service:8004/health

# Flag
curl http://flag-service:8002/health
 (GitOps)

1. Faça as alterações no código
2. Commit e push para main
3. O CI/CD automaticamente:
   - Fará o build e push da imagem
   - Atualizará o manifest GitOps com a nova tag
4. ArgoCD detecta a mudança e faz deploy automaticamente

**Acompanhe pelo ArgoCD UI:**
```bash
make argocd-ui
# Acesse: https://localhost:8080
```

### Rollback

**Via Git:**
```bash
git revert HEAD
git push origin main
# ArgoCD aplicará a versão anterior
```

**Via ArgoCD UI:**
1. Acesse a aplicação
2. Clique em "History and Rollback"
3. Selecione a versão desejada🔄 Atualizações

### Atualizar um Serviço

1. Faça as alterações no código
2. Commit e push para main
3. O CI/CD automaticamente fará o build e push
4. Atualize o deployment:

```bash
# Opção 1: Restart para puxar :latest
kubectl rollout restart deployment/<service-name> -n togglemaster

# Opção 2: Tag específica
kubectl set image deployment/<service-name> \
  <container-name>=gru.ocir.io/<namespace>/<project>/<service>:<commit-sha> \
  -n togglemaster
```gitops/                     # GitOps Repository
│   ├── apps/                   # ArgoCD Applications
│   │   ├── analytics-service.yaml
│   │   ├── auth-service.yaml
│   │   ├── evaluation-service.yaml
│   │   ├── flag-service.yaml
│   │   └── targeting-service.yaml
│   ├── manifests/              # Kubernetes manifests
│   │   ├── analytics-service/
│   │   ├── auth-service/
│   │   ├── evaluation-service/
│   │   ├── flag-service/
│   │   ├── targeting-service/
│   │   ├── namespace/
│   │   └── ingress/
│   ├── argocd/                 # ArgoCD installation
│   │   ├── install.sh
│   │   └── README.md
│   ├── GITOPS-GUIDE.md
│   ├── ARGOCD-UI.md
│   └── README.md
├── Kubernetes/                 # Manifestos Kubernetes (source)
│   ├── analytics-service/
│   ├── auth-service/
│   ├── evaluation-service/
│   ├── flag-service/
│   ├── targeting-service/
│   ├── namespace/
│   ├── nginx-ingress/
│   ├── configure-ocir.sh       # Script de configuração
│   ├── create-ocir-secret.sh   # Script para criar secret
│   └── DEPLOY.md              # Guia de deploy
├── terraform/                  # Infraestrutura as Code
│   ├── main.tf
│   ├── networking.tf
│   ├── oke.tf
│   ├── database.tf
│   ├── registry.tf
│   ├── nosql.tf
│   ├── messaging.tf
│   └── outputs.tf
├── Makefile                    # Comandos automatizados
├── README.md                   # Este arquivo
├── QUICKSTART.md              # Guia rápido
│   ├── nginx-ingress/
│   ├── configure-ocir.sh       # Script de configuração
│   └── DEPLOY.md              # Guia de deploy
├── terraform/                  # Infraestrutura as Code
│   ├── main.tf
│   ├── networking.tf
│   ├── oke.tf
│   ├── database.tf
│   ├── registry.tf
│   ├── nosql.tf
│   ├── messaging.tf
│   └── outputs.tf
└── envs/
    └── dev.tfvars
```

## 🤝 Contribuindo

1. Crie uma branch: `git checkout -b feature/nova-feature`
2. Faça suas alterações
3. Rode os testes localmente
4. Commit: `git commit -m "Adiciona nova feature"`
5. Push: `git push origin feature/nova-feature`
6. Abra um Pull Request

O CI/CD rodará automaticamente em todos os PRs.

## 📄 Licença

[Adicione sua licença aqui]
