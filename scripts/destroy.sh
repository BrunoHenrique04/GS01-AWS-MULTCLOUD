#!/usr/bin/env bash
# destroy.sh — Pipeline de destruição completa
# Uso: bash scripts/destroy.sh
set -euo pipefail

RM="566277"
REGION="us-east-1"
EKS_NAME="fiap-eks-rm${RM}"
NAMESPACE="rm${RM}"

echo "=========================================="
echo " PayBR Fintech — Pipeline Destroy"
echo "=========================================="

# Remove namespace + LB primeiro
kubectl delete namespace ${NAMESPACE} --ignore-not-found || true
echo ">>> Aguardando delecao do Load Balancer..."
sleep 30

# Terraform destroy
cd terraform
terraform destroy -auto-approve
cd ..

echo ""
echo "✅ Recursos removidos com sucesso."
