.PHONY: help init plan apply destroy deploy logs clean config-k8s

# Variáveis
TERRAFORM_DIR := terraform
K8S_DIR := Kubernetes
NAMESPACE := togglemaster

help: ## Mostra esta mensagem de ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

## ==== ArgoCD & GitOps ====

install-argocd: ## Instala ArgoCD no cluster
	@bash gitops/argocd/install.sh

configure-argocd-apps: ## Configura Applications do ArgoCD
	@bash gitops/configure-apps.sh

apply-argocd-apps: ## Aplica as Applications do ArgoCD
	kubectl apply -f gitops/apps/

argocd-password: ## Mostra a senha do ArgoCD
	@echo "Usuário: admin"
	@echo "Senha:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

argocd-ui: ## Abre port-forward para UI do ArgoCD (localhost:8080)
	kubectl port-forward svc/argocd-server -n argocd 8080:443

argocd-status: ## Mostra status de todas as applications
	kubectl get applications -n argocd

argocd-sync-all: ## Sincroniza todas as applications (requer ArgoCD CLI)
	argocd app sync --all

## ==== Terraform ====

init: ## Inicializa o Terraform
	cd $(TERRAFORM_DIR) && terraform init

plan: ## Executa terraform plan
	cd $(TERRAFORM_DIR) && terraform plan

apply: ## Aplica a infraestrutura Terraform
	cd $(TERRAFORM_DIR) && terraform apply

destroy: ## Destroi a infraestrutura Terraform
	cd $(TERRAFORM_DIR) && terraform destroy

tf-output: ## Mostra os outputs do Terraform
	cd $(TERRAFORM_DIR) && terraform output

## ==== Kubernetes ====

config-k8s: ## Configura kubectl para o cluster OKE
config-k8s: ## Configura kubectl para o cluster EKS
	@echo "Execute: aws eks update-kubeconfig --name <cluster-name> --region <region>"

create-namespace: ## Cria o namespace togglemaster
	kubectl apply -f $(K8S_DIR)/namespace/namespace.yaml

create-secret: ## Cria o image pull secret interativamente
	@bash $(K8S_DIR)/create-ecr-secret.sh

configure-deployments: ## Configura as imagens nos deployments
	@bash $(K8S_DIR)/configure-ecr.sh

configure-endpoints: ## Preenche endpoints OCI nos manifests usando Terraform outputs
configure-endpoints: ## Preenche endpoints AWS nos manifests usando Terraform outputs
	@bash $(K8S_DIR)/configure-aws-endpoints.sh

deploy-all: ## Deploy de todos os serviços
	@echo "Aplicando ConfigMaps e Secrets..."
	kubectl apply -f $(K8S_DIR)/analytics-service/configmap.yaml
	kubectl apply -f $(K8S_DIR)/analytics-service/secret.yaml
	kubectl apply -f $(K8S_DIR)/auth-service/configmap.yaml
	kubectl apply -f $(K8S_DIR)/auth-service/secret.yaml
	kubectl apply -f $(K8S_DIR)/evaluation-service/configmap.yaml
	kubectl apply -f $(K8S_DIR)/evaluation-service/secret.yaml
	kubectl apply -f $(K8S_DIR)/flag-service/configmap.yaml
	kubectl apply -f $(K8S_DIR)/flag-service/secret.yaml
	kubectl apply -f $(K8S_DIR)/targeting-service/configmap.yaml
	kubectl apply -f $(K8S_DIR)/targeting-service/secret.yaml
	@echo ""
	@echo "Aplicando Database Jobs..."
	kubectl apply -f $(K8S_DIR)/auth-service/db/
	kubectl apply -f $(K8S_DIR)/flag-service/db/
	kubectl apply -f $(K8S_DIR)/targeting-service/db/
	@echo ""
	@echo "Aplicando Deployments e Services..."
	kubectl apply -f $(K8S_DIR)/analytics-service/deployment.yaml
	kubectl apply -f $(K8S_DIR)/analytics-service/service.yaml
	kubectl apply -f $(K8S_DIR)/analytics-service/hpa.yaml
	kubectl apply -f $(K8S_DIR)/auth-service/deployment.yaml
	kubectl apply -f $(K8S_DIR)/auth-service/service.yaml
	kubectl apply -f $(K8S_DIR)/evaluation-service/deployment.yaml
	kubectl apply -f $(K8S_DIR)/evaluation-service/service.yaml
	kubectl apply -f $(K8S_DIR)/evaluation-service/hpa.yaml
	kubectl apply -f $(K8S_DIR)/flag-service/deployment.yaml
	kubectl apply -f $(K8S_DIR)/flag-service/service.yaml
	kubectl apply -f $(K8S_DIR)/targeting-service/deployment.yaml
	kubectl apply -f $(K8S_DIR)/targeting-service/service.yaml
	@echo ""
	@echo "Aplicando Ingress..."
	kubectl apply -f $(K8S_DIR)/nginx-ingress/ingress.yaml
	@echo ""
	@echo "✅ Deploy completo!"

deploy-analytics: ## Deploy do analytics-service
	kubectl apply -f $(K8S_DIR)/analytics-service/

deploy-auth: ## Deploy do auth-service
	kubectl apply -f $(K8S_DIR)/auth-service/

deploy-evaluation: ## Deploy do evaluation-service
	kubectl apply -f $(K8S_DIR)/evaluation-service/

deploy-flag: ## Deploy do flag-service
	kubectl apply -f $(K8S_DIR)/flag-service/

deploy-targeting: ## Deploy do targeting-service
	kubectl apply -f $(K8S_DIR)/targeting-service/

## ==== Monitoramento ====

status: ## Mostra status de todos os recursos
	kubectl get all -n $(NAMESPACE)

pods: ## Lista todos os pods
	kubectl get pods -n $(NAMESPACE)

services: ## Lista todos os services
	kubectl get svc -n $(NAMESPACE)

ingress: ## Mostra o ingress
	kubectl get ingress -n $(NAMESPACE)

logs-analytics: ## Mostra logs do analytics-service
	kubectl logs -f deployment/analytics-service -n $(NAMESPACE)

logs-auth: ## Mostra logs do auth-service
	kubectl logs -f deployment/auth-service -n $(NAMESPACE)

logs-evaluation: ## Mostra logs do evaluation-service
	kubectl logs -f deployment/evaluation-service -n $(NAMESPACE)

logs-flag: ## Mostra logs do flag-service
	kubectl logs -f deployment/flag-service -n $(NAMESPACE)

logs-targeting: ## Mostra logs do targeting-service
	kubectl logs -f deployment/targeting-service -n $(NAMESPACE)

describe-pod: ## Descreve um pod específico (uso: make describe-pod POD=pod-name)
	kubectl describe pod $(POD) -n $(NAMESPACE)

events: ## Mostra eventos recentes
	kubectl get events -n $(NAMESPACE) --sort-by='.lastTimestamp'

## ==== Rollout ====

restart-all: ## Reinicia todos os deployments
	kubectl rollout restart deployment -n $(NAMESPACE)

restart-analytics: ## Reinicia analytics-service
	kubectl rollout restart deployment/analytics-service -n $(NAMESPACE)

restart-auth: ## Reinicia auth-service
	kubectl rollout restart deployment/auth-service -n $(NAMESPACE)

restart-evaluation: ## Reinicia evaluation-service
	kubectl rollout restart deployment/evaluation-service -n $(NAMESPACE)

restart-flag: ## Reinicia flag-service
	kubectl rollout restart deployment/flag-service -n $(NAMESPACE)

restart-targeting: ## Reinicia targeting-service
	kubectl rollout restart deployment/targeting-service -n $(NAMESPACE)

rollout-status: ## Status do rollout de um deployment (uso: make rollout-status DEPLOY=deployment-name)
	kubectl rollout status deployment/$(DEPLOY) -n $(NAMESPACE)

## ==== Limpeza ====

delete-all: ## Remove todos os recursos do namespace (CUIDADO!)
	kubectl delete all --all -n $(NAMESPACE)

delete-namespace: ## Remove o namespace (CUIDADO!)
	kubectl delete namespace $(NAMESPACE)

clean: ## Limpa arquivos temporários locais
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name ".pytest_cache" -delete

## ==== Desenvolvimento ====

local-analytics: ## Roda analytics-service localmente
	cd $(K8S_DIR)/analytics-service/analytics-service && pip install -r requirements.txt && python app.py

local-auth: ## Roda auth-service localmente
	cd $(K8S_DIR)/auth-service/auth-service && go run main.go

local-evaluation: ## Roda evaluation-service localmente
	cd $(K8S_DIR)/evaluation-service/evaluation-service && go run main.go

local-flag: ## Roda flag-service localmente
	cd $(K8S_DIR)/flag-service/flag-service && pip install -r requirements.txt && python app.py

local-targeting: ## Roda targeting-service localmente
	cd $(K8S_DIR)/targeting-service/targeting-service && pip install -r requirements.txt && python app.py

## ==== Utilitários ====

shell-analytics: ## Abre shell no pod analytics-service
	kubectl exec -it deployment/analytics-service -n $(NAMESPACE) -- /bin/sh

shell-auth: ## Abre shell no pod auth-service
	kubectl exec -it deployment/auth-service -n $(NAMESPACE) -- /bin/sh

shell-evaluation: ## Abre shell no pod evaluation-service
	kubectl exec -it deployment/evaluation-service -n $(NAMESPACE) -- /bin/sh

shell-flag: ## Abre shell no pod flag-service
	kubectl exec -it deployment/flag-service -n $(NAMESPACE) -- /bin/sh

shell-targeting: ## Abre shell no pod targeting-service
	kubectl exec -it deployment/targeting-service -n $(NAMESPACE) -- /bin/sh

port-forward-analytics: ## Port forward analytics (localhost:8005)
	kubectl port-forward svc/analytics-service 8005:8005 -n $(NAMESPACE)

port-forward-auth: ## Port forward auth (localhost:8001)
	kubectl port-forward svc/auth-service 8001:8001 -n $(NAMESPACE)

port-forward-evaluation: ## Port forward evaluation (localhost:8004)
	kubectl port-forward svc/evaluation-service 8004:8004 -n $(NAMESPACE)

port-forward-flag: ## Port forward flag (localhost:8002)
	kubectl port-forward svc/flag-service 8002:8002 -n $(NAMESPACE)

port-forward-targeting: ## Port forward targeting (localhost:8003)
	kubectl port-forward svc/targeting-service 8003:8003 -n $(NAMESPACE)
