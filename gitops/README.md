# GitOps Repository - ToggleMaster

Este diretório contém os manifestos Kubernetes para deploy via ArgoCD.

## Estrutura

```
gitops/
├── apps/                       # ArgoCD Applications
│   ├── analytics-service.yaml
│   ├── auth-service.yaml
│   ├── evaluation-service.yaml
│   ├── flag-service.yaml
│   └── targeting-service.yaml
├── manifests/                  # Manifestos K8s organizados por serviço
│   ├── analytics-service/
│   ├── auth-service/
│   ├── evaluation-service/
│   ├── flag-service/
│   ├── targeting-service/
│   ├── namespace/
│   └── ingress/
└── argocd/                     # Instalação do ArgoCD
    ├── install.yaml
    └── README.md
```

## Fluxo GitOps

1. **CI Pipeline** (GitHub Actions) → Build, Test, Security Scan → Push image para OCIR
2. **CI atualiza tag** → Abre PR/commit no repositório GitOps com nova imagem
3. **ArgoCD monitora** → Detecta mudança no repositório GitOps
4. **ArgoCD sincroniza** → Aplica as mudanças no cluster OKE automaticamente

## Vantagens

- ✅ Single source of truth (manifests no Git)
- ✅ Rollback fácil (git revert)
- ✅ Auditoria completa (git history)
- ✅ Deploy declarativo e automático
- ✅ Visibilidade via ArgoCD UI
