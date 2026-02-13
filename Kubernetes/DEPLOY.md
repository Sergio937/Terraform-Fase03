# Guia de Deploy dos Microsservicos no EKS

## Pré-requisitos

1. **Terraform aplicado** - O cluster EKS e os repositórios ECR devem estar criados
2. **kubectl configurado** - Conectado ao cluster EKS
3. **Credenciais AWS** - Access Key/Secret configurados (CLI)

## Passo 1: Criar o Namespace

```bash
kubectl apply -f Kubernetes/namespace/namespace.yaml
```

## Passo 2: Criar o Image Pull Secret para ECR (opcional)

Antes de aplicar os deployments, crie o secret para autenticar no ECR (se necessario):

```bash
# Obtenha as informações necessárias:
# - AWS_ACCOUNT_ID: ID da conta AWS
# - AWS_REGION: regiao

aws ecr get-login-password --region <AWS_REGION> | \
  kubectl create secret docker-registry ecr-secret \
    --docker-server=<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com \
    --docker-username=AWS \
    --docker-password-stdin \
    --namespace=togglemaster
```

## Passo 3: Atualizar os Deployments com a URL correta do ECR

Execute a automacao para preencher endpoints e imagens via outputs:
```bash
make configure-endpoints
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
# Instalar NGINX Ingress Controller (se ainda nao estiver instalado)
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

O GitHub Actions ira automaticamente fazer push de novas imagens para o ECR quando houver push na branch `main`. Para atualizar o deployment:

```bash
# Opção 1: Restart do deployment para puxar a tag :latest
kubectl rollout restart deployment/analytics-service -n togglemaster

# Opção 2: Atualizar com uma tag específica de commit
kubectl set image deployment/analytics-service \
  analytics-service=<account-id>.dkr.ecr.<region>.amazonaws.com/<project>/analytics-service:a1b2c3d \
  -n togglemaster

# Ver o status do rollout
kubectl rollout status deployment/analytics-service -n togglemaster
```

## Configuração dos Secrets do GitHub

Para que o CI/CD funcione, configure estes secrets no GitHub:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `PROJECT_NAME`
