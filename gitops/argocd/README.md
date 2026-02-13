# ArgoCD Installation Guide

## Instalacao do ArgoCD no cluster EKS

### Opção 1: Via kubectl (Recomendado)

```bash
# Criar namespace do ArgoCD
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Aguardar pods ficarem prontos
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Opção 2: Via arquivo local

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f gitops/argocd/install.yaml
```

## Acessar a UI do ArgoCD

### 1. Obter senha inicial do admin

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### 2. Expor o serviço

**Opção A: Port Forward (desenvolvimento)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Acesse: https://localhost:8080
- User: `admin`
- Password: (obtida no passo 1)

**Opção B: LoadBalancer (produção)**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc argocd-server -n argocd
```
Use o EXTERNAL-IP para acessar a UI.

**Opção C: Ingress (recomendado para produção)**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.seu-dominio.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

## Configurar CLI do ArgoCD (opcional)

```bash
# Download
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login
argocd login <ARGOCD-SERVER> --username admin --password <PASSWORD>

# Alterar senha
argocd account update-password
```

## Aplicar as Applications

Após a instalação do ArgoCD, aplique as Applications:

```bash
kubectl apply -f gitops/apps/
```

## Verificar Status

```bash
# Via kubectl
kubectl get applications -n argocd

# Via CLI
argocd app list

# Ver detalhes de uma app
argocd app get analytics-service
```

## Sincronização Manual

```bash
# Sincronizar uma aplicação
argocd app sync analytics-service

# Sincronizar todas
argocd app sync --all
```

## Troubleshooting

### Pods não iniciam
```bash
kubectl get pods -n argocd
kubectl logs -n argocd deployment/argocd-server
```

### Senha não funciona
```bash
# Resetar senha
kubectl -n argocd patch secret argocd-secret -p '{"data": {"admin.password": null, "admin.passwordMtime": null}}'
kubectl -n argocd scale deployment argocd-server --replicas=0
kubectl -n argocd scale deployment argocd-server --replicas=1
```

### Aplicação out of sync
```bash
# Ver diff
argocd app diff analytics-service

# Forçar sync
argocd app sync analytics-service --force
```
