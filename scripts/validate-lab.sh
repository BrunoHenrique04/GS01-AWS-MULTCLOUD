#!/bin/bash
# validate-lab.sh — FIAP Lab 4 — AWS EKS
# Uso: bash scripts/validate-lab.sh

RM="566277"
CTX_EKS="arn:aws:eks:us-east-1:ACCOUNT_ID:cluster/fiap-eks-rm${RM}"

PASS=0
FAIL=0

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" &>/dev/null; then
    echo "  ✅ PASS: $desc"
    PASS=$((PASS+1))
  else
    echo "  ❌ FAIL: $desc"
    FAIL=$((FAIL+1))
  fi
}

echo ""
echo "=========================================="
echo " VALIDAÇÃO LAB KUBERNETES - AWS EKS"
echo " Aluno: rm${RM}"
echo "=========================================="
echo ""

check "Cluster acessivel" "kubectl --context=${CTX_EKS} cluster-info"
check "2 nos Ready" "[ $(kubectl --context=${CTX_EKS} get nodes --no-headers | grep -c Ready) -eq 2 ]"
check "Pods Running" "kubectl --context=${CTX_EKS} get pods -n rm${RM} | grep -q Running"
check "Service criado" "kubectl --context=${CTX_EKS} get svc paybr-api-svc -n rm${RM}"
check "ConfigMap existe" "kubectl --context=${CTX_EKS} get configmap paybr-config -n rm${RM}"
check "Deployment existe" "kubectl --context=${CTX_EKS} get deployment paybr-api -n rm${RM}"
check "2 replicas" "[ $(kubectl --context=${CTX_EKS} get deployment paybr-api -n rm${RM} -o jsonpath='{.spec.replicas}') -eq 2 ]"

echo ""
echo "=========================================="
echo " RESULTADO: ${PASS} PASS | ${FAIL} FAIL"
echo "=========================================="

if [ $FAIL -eq 0 ]; then
  echo ""
  echo "📸 PayBR URL:"
  kubectl --context=${CTX_EKS} get svc paybr-api-svc -n rm${RM} \
    -o jsonpath='http://{.status.loadBalancer.ingress[0].hostname}{"\n"}'
fi
