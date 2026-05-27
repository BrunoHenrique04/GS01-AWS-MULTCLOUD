#!/bin/bash
# cleanup.sh — FIAP Lab 4 — Limpeza AWS EKS
# Uso: bash scripts/cleanup.sh

RM="566277"
AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="fiap-eks-rm${RM}"

echo "⚠  LIMPEZA DE RECURSOS - AWS EKS"
echo "   Cluster: ${EKS_CLUSTER_NAME}"
echo ""

# Deletar namespace (remove Load Balancer automaticamente)
echo ">>> Removendo namespace rm${RM}..."
kubectl delete namespace rm${RM} --ignore-not-found
echo ">>> Aguardando delecao do Load Balancer..."
sleep 30

# Deletar cluster EKS
echo ">>> Deletando cluster EKS..."
eksctl delete cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}

echo ""
echo "✅ Limpeza concluida. Verifique no console AWS."
