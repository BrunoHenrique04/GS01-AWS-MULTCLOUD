# FIAP — Cloud Computing
## Lab 4 — Kubernetes na AWS (EKS)

**Aluno:** RM566277 — BRUNO HENRIQUE MARTINS FERREIRA  
**Caso:** PayBR Fintech — Plataforma de Pagamentos na AWS

---

## Contexto da Empresa

A **PayBR** é uma fintech brasileira de médio porte especializada em pagamentos instantâneos (PIX), cartões pré-pagos e câmbio digital. Com mais de 2,3 milhões de usuários ativos e processando R$ 4,8 bilhões/mês em transações, a empresa enfrenta requisitos rigorosos de disponibilidade (SLA 99,99%), latência (<150ms P99) e conformidade regulatória (LGPD + BACEN Resolução 4.893).

### Problema Atual

A arquitetura legada é monolítica em um único datacenter on-premise em São Paulo. Nos últimos 6 meses ocorreram 3 incidentes de indisponibilidade, acumulando R$ 1,2 milhão em multas.

### Solução Proposta

Migração para **Amazon EKS** (Elastic Kubernetes Service) na região **us-east-1**, containerizando todos os microserviços da PayBR em clusters Kubernetes gerenciados.

| Componente          | Serviço AWS | Função                                    |
|---------------------|-------------|-------------------------------------------|
| API Gateway         | EKS (fiap-eks-rm566277) | paybr-api · Auth Service · Fraud Detection |
| Frontend            | EKS (fiap-eks-rm566277) | Interface Web do PayBR                     |
| Notificações        | EKS (fiap-eks-rm566277) | Notification Service · Compliance Audit    |
| Database            | Amazon RDS (PostgreSQL) | Dados transacionais                        |

---

## Pré-requisitos

```bash
aws --version        # aws-cli/2.x.x
kubectl version --client  # v1.31.x
eksctl version       # 0.19x.x
```

## Credenciais AWS

```bash
aws configure
# Access Key ID:    [fornecida pelo professor]
# Secret Access Key: [fornecida pelo professor]
# Default region:   us-east-1
# Output format:    json

aws sts get-caller-identity  # verificar autenticação
```

---

## 1. Criar o Cluster EKS

```bash
export RM=566277
export AWS_REGION="us-east-1"
export EKS_CLUSTER_NAME="fiap-eks-rm${RM}"

eksctl create cluster \
  --name ${EKS_CLUSTER_NAME} \
  --version 1.31 \
  --region ${AWS_REGION} \
  --nodegroup-name fiap-ng-rm${RM} \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed \
  --with-oidc \
  --tags "aluno=rm${RM},projeto=fiap-multicloud,lab=kubernetes"
```

⏱️ Tempo estimado: **15-20 minutos**

---

## 2. Configurar kubectl

```bash
aws eks update-kubeconfig \
  --name ${EKS_CLUSTER_NAME} \
  --region ${AWS_REGION}

kubectl cluster-info
kubectl get nodes -o wide
# Esperado: 2 nós t3.medium com status Ready
```

---

## 3. Deploy da Aplicação PayBR

```bash
kubectl create namespace rm${RM}
kubectl apply -f manifests/eks/deployment-eks.yaml
kubectl rollout status deployment/paybr-api -n rm${RM}
```

### Verificar o deploy

```bash
kubectl get pods -n rm${RM} -o wide
kubectl get svc paybr-api-svc -n rm${RM} --watch
# Aguardar EXTERNAL-IP (DNS do Load Balancer)
```

### Testar a aplicação

```bash
export EKS_LB=$(kubectl get svc paybr-api-svc -n rm${RM} \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "PayBR URL: http://${EKS_LB}"
curl http://${EKS_LB}
# Deve retornar página PayBR com badge "AWS / EKS"
```

---

## 4. ConfigMap

```bash
kubectl apply -f - << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: paybr-config
  namespace: rm${RM}
data:
  CLOUD_PROVIDER: "AWS"
  REGION: "us-east-1"
  CLUSTER_TYPE: "EKS Managed"
  DB_HOST: "rds.internal"
  FEATURE_FLAGS: "fraud-detection=true,auth=true,notifications=true"
EOF
```

---

## 5. Exploração do Cluster

```bash
# Ver todos os recursos
kubectl get all -n rm${RM}

# Descrever um pod
POD=$(kubectl get pod -n rm${RM} -l app=paybr-api -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod ${POD} -n rm${RM}

# Logs
kubectl logs ${POD} -n rm${RM}

# Escalar
kubectl scale deployment paybr-api -n rm${RM} --replicas=3
kubectl scale deployment paybr-api -n rm${RM} --replicas=2

# Port-forward
kubectl port-forward svc/paybr-api-svc 8080:80 -n rm${RM}
# Acessar: http://localhost:8080
```

---

## 6. Validação

```bash
bash scripts/validate-lab.sh
```

---

## 7. Limpeza

```bash
bash scripts/cleanup.sh
```

---

## Estrutura do Repositório

```
├── manifests/
│   └── eks/
│       └── deployment-eks.yaml    # paybr-api (nginx + PayBR branding)
├── scripts/
│   ├── validate-lab.sh            # Validação automática
│   └── cleanup.sh                 # Limpeza de recursos
└── README.md
```

## Resumo — O que você aprendeu

| Conceito            | Comando                                    |
|---------------------|--------------------------------------------|
| Autenticação AWS    | `aws configure`                            |
| Criar Cluster EKS   | `eksctl create cluster`                    |
| Configurar kubectl  | `aws eks update-kubeconfig`                |
| Cost do EKS         | US$0,10/hora (control plane)               |
| Node Type           | t3.medium × 2                              |
| K8s Version         | 1.31                                       |
| Load Balancer       | DNS (AWS ELB / NLB)                        |
| Deploy              | `kubectl apply -f deployment-eks.yaml`     |
| Deletar             | `eksctl delete cluster`                    |

---

📸 **ENTREGA:** Tire um screenshot da página PayBR rodando no EKS e envie ao professor.

FIAP — Cloud Computing | Lab 4 — Kubernetes na AWS | 2026
