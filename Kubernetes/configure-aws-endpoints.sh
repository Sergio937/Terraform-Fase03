#!/bin/bash
# Preenche placeholders AWS nos manifests usando terraform output

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/terraform"

if ! command -v terraform >/dev/null 2>&1; then
  echo "Erro: terraform nao encontrado no PATH."
  exit 1
fi

if [ ! -d "$TF_DIR" ]; then
  echo "Erro: diretorio terraform nao encontrado: $TF_DIR"
  exit 1
fi

TF_OUTPUT_JSON="$(terraform -chdir="$TF_DIR" output -json)"

# Extrair outputs relevantes
# shellcheck disable=SC2046
eval "$(printf '%s' "$TF_OUTPUT_JSON" | python3 - <<'PY'
import json
import shlex
import sys

data = json.load(sys.stdin)

def get_value(name):
  item = data.get(name, {})
  if isinstance(item, dict):
    return item.get("value")
  return None

rds_endpoint = get_value("rds_endpoint") or ""
redis_endpoint = get_value("redis_primary_endpoint") or ""
sqs_url = get_value("sqs_queue_url") or ""
aws_region = get_value("aws_region") or ""
dynamo_table = get_value("dynamodb_table_name") or ""
ecr_urls = get_value("ecr_repository_urls") or {}

images = {
  "ECR_ANALYTICS_IMAGE": (ecr_urls.get("analytics_service") or "") + ":latest",
  "ECR_AUTH_IMAGE": (ecr_urls.get("auth_service") or "") + ":latest",
  "ECR_EVALUATION_IMAGE": (ecr_urls.get("evaluation_service") or "") + ":latest",
  "ECR_FLAG_IMAGE": (ecr_urls.get("flag_service") or "") + ":latest",
  "ECR_TARGETING_IMAGE": (ecr_urls.get("targeting_service") or "") + ":latest",
}

def emit(key, value):
  print(f"{key}={shlex.quote(str(value))}")

emit("AWS_RDS_ENDPOINT", rds_endpoint)
emit("AWS_REDIS_PRIMARY_ENDPOINT", redis_endpoint)
emit("AWS_SQS_QUEUE_URL", sqs_url)
emit("AWS_REGION", aws_region)
emit("AWS_DYNAMODB_TABLE_NAME", dynamo_table)

for key, value in images.items():
  emit(key, value)
PY)"

if [ -z "${AWS_RDS_ENDPOINT:-}" ]; then
  echo "Erro: output rds_endpoint esta vazio."
  exit 1
fi

if [ -z "${AWS_REDIS_PRIMARY_ENDPOINT:-}" ]; then
  echo "Erro: output redis_primary_endpoint esta vazio."
  exit 1
fi

if [ -z "${AWS_SQS_QUEUE_URL:-}" ]; then
  echo "Erro: output sqs_queue_url esta vazio."
  exit 1
fi

if [ -z "${AWS_REGION:-}" ]; then
  echo "Erro: output aws_region esta vazio."
  exit 1
fi

if [ -z "${AWS_DYNAMODB_TABLE_NAME:-}" ]; then
  echo "Erro: output dynamodb_table_name esta vazio."
  exit 1
fi

FILES=(
  "$ROOT_DIR/Kubernetes/auth-service/configmap.yaml"
  "$ROOT_DIR/Kubernetes/auth-service/db/secret.yaml"
  "$ROOT_DIR/Kubernetes/flag-service/configmap.yaml"
  "$ROOT_DIR/Kubernetes/flag-service/db/secret.yaml"
  "$ROOT_DIR/Kubernetes/targeting-service/configmap.yaml"
  "$ROOT_DIR/Kubernetes/targeting-service/db/secret.yaml"
  "$ROOT_DIR/Kubernetes/evaluation-service/configmap.yaml"
  "$ROOT_DIR/Kubernetes/analytics-service/configmap.yaml"
  "$ROOT_DIR/Kubernetes/analytics-service/deployment.yaml"
  "$ROOT_DIR/Kubernetes/auth-service/deployment.yaml"
  "$ROOT_DIR/Kubernetes/evaluation-service/deployment.yaml"
  "$ROOT_DIR/Kubernetes/flag-service/deployment.yaml"
  "$ROOT_DIR/Kubernetes/targeting-service/deployment.yaml"
  "$ROOT_DIR/gitops/manifests/auth-service/configmap.yaml"
  "$ROOT_DIR/gitops/manifests/auth-service/db/secret.yaml"
  "$ROOT_DIR/gitops/manifests/flag-service/configmap.yaml"
  "$ROOT_DIR/gitops/manifests/flag-service/db/secret.yaml"
  "$ROOT_DIR/gitops/manifests/targeting-service/configmap.yaml"
  "$ROOT_DIR/gitops/manifests/targeting-service/db/secret.yaml"
  "$ROOT_DIR/gitops/manifests/evaluation-service/configmap.yaml"
  "$ROOT_DIR/gitops/manifests/analytics-service/configmap.yaml"
  "$ROOT_DIR/gitops/manifests/analytics-service/deployment.yaml"
  "$ROOT_DIR/gitops/manifests/auth-service/deployment.yaml"
  "$ROOT_DIR/gitops/manifests/evaluation-service/deployment.yaml"
  "$ROOT_DIR/gitops/manifests/flag-service/deployment.yaml"
  "$ROOT_DIR/gitops/manifests/targeting-service/deployment.yaml"
)

export AWS_RDS_ENDPOINT AWS_REDIS_PRIMARY_ENDPOINT AWS_SQS_QUEUE_URL AWS_REGION AWS_DYNAMODB_TABLE_NAME
export ECR_ANALYTICS_IMAGE ECR_AUTH_IMAGE ECR_EVALUATION_IMAGE ECR_FLAG_IMAGE ECR_TARGETING_IMAGE

python3 - "${FILES[@]}" <<'PY'
import os
import sys

replacements = {
  "${AWS_RDS_ENDPOINT}": os.environ.get("AWS_RDS_ENDPOINT", ""),
  "${AWS_REDIS_PRIMARY_ENDPOINT}": os.environ.get("AWS_REDIS_PRIMARY_ENDPOINT", ""),
  "${AWS_SQS_QUEUE_URL}": os.environ.get("AWS_SQS_QUEUE_URL", ""),
  "${AWS_REGION}": os.environ.get("AWS_REGION", ""),
  "${AWS_DYNAMODB_TABLE_NAME}": os.environ.get("AWS_DYNAMODB_TABLE_NAME", ""),
  "${ECR_ANALYTICS_IMAGE}": os.environ.get("ECR_ANALYTICS_IMAGE", ""),
  "${ECR_AUTH_IMAGE}": os.environ.get("ECR_AUTH_IMAGE", ""),
  "${ECR_EVALUATION_IMAGE}": os.environ.get("ECR_EVALUATION_IMAGE", ""),
  "${ECR_FLAG_IMAGE}": os.environ.get("ECR_FLAG_IMAGE", ""),
  "${ECR_TARGETING_IMAGE}": os.environ.get("ECR_TARGETING_IMAGE", ""),
}

files = sys.argv[1:]
for path in files:
  with open(path, "r", encoding="utf-8") as f:
    original = f.read()
  updated = original
  for key, value in replacements.items():
    updated = updated.replace(key, value)
  if updated != original:
    with open(path, "w", encoding="utf-8") as f:
      f.write(updated)
    print(f"Atualizado: {path}")
  else:
    print(f"Sem alteracao: {path}")
PY

echo ""
echo "✅ Placeholders AWS preenchidos com sucesso."
