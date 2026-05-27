#!/usr/bin/env bash
# deploy.sh — Pipeline completo: infra + app + validação
# Uso: bash scripts/deploy.sh
set -euo pipefail

RM="566277"
REGION="us-east-1"
EKS_NAME="fiap-eks-rm${RM}"
NAMESPACE="rm${RM}"

echo "=========================================="
echo " PayBR Fintech — Pipeline Deploy EKS"
echo " Aluno: rm${RM}"
echo "=========================================="

# ── 1. Terraform — Infraestrutura ──────────────
echo ""
echo ">>> [1/6] Provisionando VPC + EKS via Terraform..."
cd terraform
terraform init -upgrade
terraform apply -auto-approve
cd ..

# ── 2. Configurar kubectl ──────────────────────
echo ""
echo ">>> [2/6] Configurando kubectl..."
aws eks update-kubeconfig --name ${EKS_NAME} --region ${REGION}
kubectl cluster-info

# ── 3. Aguardar nós ────────────────────────────
echo ""
echo ">>> [3/6] Aguardando nos ficarem Ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s
kubectl get nodes -o wide

# ── 4. Deploy da aplicação ─────────────────────
echo ""
echo ">>> [4/6] Deploy PayBR..."
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f manifests/eks/deployment-eks.yaml
kubectl rollout status deployment/paybr-api -n ${NAMESPACE} --timeout=180s

# ── 5. ConfigMap ───────────────────────────────
echo ""
echo ">>> [5/6] ConfigMap..."
kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: paybr-config
  namespace: ${NAMESPACE}
data:
  CLOUD_PROVIDER: "AWS"
  REGION: "${REGION}"
  CLUSTER_TYPE: "EKS Managed"
  DB_HOST: "rds.internal"
  FEATURE_FLAGS: "fraud-detection=true,auth=true,notifications=true"
EOF

# ── 6. Validação ───────────────────────────────
echo ""
echo ">>> [6/6] Validando..."
kubectl get pods -n ${NAMESPACE} -o wide
kubectl get svc -n ${NAMESPACE}

echo ""
echo "=========================================="
echo " Pipeline concluido com sucesso!"
echo "=========================================="

EKS_LB=$(kubectl get svc paybr-api-svc -n ${NAMESPACE} \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pendente")
echo " PayBR URL: http://${EKS_LB}"
echo ""
