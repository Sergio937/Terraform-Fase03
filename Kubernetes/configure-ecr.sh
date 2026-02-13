#!/bin/bash
# Wrapper para configurar imagens do ECR via outputs do Terraform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/configure-aws-endpoints.sh"
