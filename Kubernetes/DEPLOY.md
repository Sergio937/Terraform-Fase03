# Guia de Deploy dos Microsserviços no OKE

## Pré-requisitos

1. **Terraform aplicado** - O cluster OKE e os repositórios OCIR devem estar criados
2. **kubectl configurado** - Conectado ao cluster OKE
3. **Credenciais OCI** - Auth token gerado no OCI

## Passo 1: Criar o Namespace

```bash
kubectl apply -f Kubernetes/namespace/namespace.yaml
```

## Passo 2: Criar o Image Pull Secret para OCIR

Antes de aplicar os deployments, crie o secret para autenticar no OCIR:

```bash
# Obtenha as informações necessárias:
# - NAMESPACE: seu tenancy namespace (ex: grxyz123)
# - USERNAME: seu usuário OCI (ex: oracleidentitycloudservice/seu.email@exemplo.com)
# - AUTH_TOKEN: token gerado em OCI Console > User Settings > Auth Tokens
# - PROJECT_NAME: nome do projeto usado no Terraform

kubectl create secret docker-registry ocir-secret \
  --docker-server=gru.ocir.io \
  --docker-username='<NAMESPACE>/<USERNAME>' \
  --docker-password='<AUTH_TOKEN>' \
  --namespace=togglemaster
```

## Passo 3: Atualizar os Deployments com a URL correta do OCIR

Edite cada deployment (analytics, auth, evaluation, flag, targeting) e substitua:
- `<namespace>` pelo namespace da sua tenancy OCI
- `<project-name>` pelo valor da variável `project_name` do Terraform

Exemplo:
```yaml
image: gru.ocir.io/grxyz123/togglemaster/analytics-service:latest
```

Você pode fazer isso com sed:
```bash
NAMESPACE="seu-namespace"
PROJECT="seu-projeto"

for service in analytics-service auth-service evaluation-service flag-service targeting-service; do
  sed -i "s|<namespace>|$NAMESPACE|g" Kubernetes/$service/deployment.yaml
  sed -i "s|<project-name>|$PROJECT|g" Kubernetes/$service/deployment.yaml
done
```

## Passo 4: Aplicar ConfigMaps e Secrets

```bash
# Analytics Service
kubectl apply -f Kubernetes/analytics-service/configmap.yaml
kubectl apply -f Kubernetes/analytics-service/secret.yaml

# Auth Service
kubectl apply -f Kubernetes/auth-service/configmap.yaml
kubectl apply -f Kubernetes/auth-service/secret.yaml
kubectl apply -f Kubernetes/auth-service/db/configmap.yaml
kubectl apply -f Kubernetes/auth-service/db/secret.yaml
kubectl apply -f Kubernetes/auth-service/db/job.yaml

# Evaluation Service
kubectl apply -f Kubernetes/evaluation-service/configmap.yaml
kubectl apply -f Kubernetes/evaluation-service/secret.yaml

# Flag Service
kubectl apply -f Kubernetes/flag-service/configmap.yaml
kubectl apply -f Kubernetes/flag-service/secret.yaml
kubectl apply -f Kubernetes/flag-service/db/configmap.yaml
kubectl apply -f Kubernetes/flag-service/db/secret.yaml
kubectl apply -f Kubernetes/flag-service/db/job.yaml

# Targeting Service
kubectl apply -f Kubernetes/targeting-service/configmap.yaml
kubectl apply -f Kubernetes/targeting-service/secret.yaml
kubectl apply -f Kubernetes/targeting-service/db/configmap.yaml
kubectl apply -f Kubernetes/targeting-service/db/secret.yaml
kubectl apply -f Kubernetes/targeting-service/db/job.yaml
```

## Passo 5: Deploy dos Serviços

```bash
# Analytics Service
kubectl apply -f Kubernetes/analytics-service/deployment.yaml
kubectl apply -f Kubernetes/analytics-service/service.yaml
kubectl apply -f Kubernetes/analytics-service/hpa.yaml

# Auth Service
kubectl apply -f Kubernetes/auth-service/deployment.yaml
kubectl apply -f Kubernetes/auth-service/service.yaml

# Evaluation Service
kubectl apply -f Kubernetes/evaluation-service/deployment.yaml
kubectl apply -f Kubernetes/evaluation-service/service.yaml
kubectl apply -f Kubernetes/evaluation-service/hpa.yaml

# Flag Service
kubectl apply -f Kubernetes/flag-service/deployment.yaml
kubectl apply -f Kubernetes/flag-service/service.yaml

# Targeting Service
kubectl apply -f Kubernetes/targeting-service/deployment.yaml
kubectl apply -f Kubernetes/targeting-service/service.yaml
```

## Passo 6: Configurar Ingress

```bash
# Instalar NGINX Ingress Controller (se ainda não estiver instalado)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Aplicar o Ingress
kubectl apply -f Kubernetes/nginx-ingress/ingress.yaml
```

## Passo 7: Verificar o Deploy

```bash
# Ver todos os pods
kubectl get pods -n togglemaster

# Ver todos os services
kubectl get svc -n togglemaster

# Ver o ingress e obter o IP externo
kubectl get ingress -n togglemaster

# Logs de um serviço específico
kubectl logs -f deployment/analytics-service -n togglemaster
```

## Atualização de Imagens via CI/CD

O GitHub Actions irá automaticamente fazer push de novas imagens para o OCIR quando houver push na branch `main`. Para atualizar o deployment:

```bash
# Opção 1: Restart do deployment para puxar a tag :latest
kubectl rollout restart deployment/analytics-service -n togglemaster

# Opção 2: Atualizar com uma tag específica de commit
kubectl set image deployment/analytics-service \
  analytics-service=gru.ocir.io/<namespace>/<project>/analytics-service:a1b2c3d \
  -n togglemaster

# Ver o status do rollout
kubectl rollout status deployment/analytics-service -n togglemaster
```

## Configuração dos Secrets do GitHub

Para que o CI/CD funcione, configure estes secrets no GitHub:

- `OCI_AUTH_TOKEN`: Auth token do OCI
- `OCI_USERNAME`: `<tenancy-namespace>/<oci-username>`
- `OCI_REGISTRY_URL`: `gru.ocir.io`
- `OCI_NAMESPACE`: namespace da tenancy
- `PROJECT_NAME`: nome do projeto (mesmo do Terraform)
