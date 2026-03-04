#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     VÉRIFICATION DES RESSOURCES AWS - bfs-gp12-prod      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

REGION="eu-south-2"
CLUSTER_NAME="eks-bfs-gp12-prod"

echo "🔍 1. CLUSTER EKS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query 'cluster.{Name:name,Status:status,Version:version}' --output table 2>/dev/null || echo "❌ Cluster non trouvé"
echo ""

echo "🔍 2. NODE GROUPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
NODEGROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups' --output text 2>/dev/null)
if [ -n "$NODEGROUPS" ]; then
    for NG in $NODEGROUPS; do
        echo "📦 $NG:"
        aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NG --region $REGION \
            --query 'nodegroup.{Status:status,Desired:scalingConfig.desiredSize,Min:scalingConfig.minSize,Max:scalingConfig.maxSize,Type:instanceTypes[0]}' \
            --output table 2>/dev/null | grep -v "^--" | grep -v "^|--"
    done
else
    echo "❌ Aucun node group trouvé"
fi
echo ""

echo "🔍 3. VPC & SUBNETS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=eks-bfs-gp12-prod-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
    echo "✅ VPC: $VPC_ID"
    SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
    echo "   Subnets: $(echo $SUBNETS | wc -w) trouvés"
else
    echo "❌ VPC non trouvé"
fi
echo ""

echo "🔍 4. CLOUDWATCH LOGS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws logs describe-log-groups --region $REGION --log-group-name-prefix "/aws/eks/eks-bfs-gp12" \
    --query 'logGroups[*].{Name:logGroupName,Retention:retentionInDays}' --output table 2>/dev/null || echo "❌ Aucun log group trouvé"
echo ""

echo "🔍 5. IAM ROLES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
for ROLE in "eks-bfs-gp12-prod-ebs-csi" "eks-bfs-gp12-prod-cluster-autoscaler" "eks-bfs-gp12-prod-aws-load-balancer-controller"; do
    ROLE_EXISTS=$(aws iam get-role --role-name $ROLE --query 'Role.RoleName' --output text 2>/dev/null)
    if [ "$ROLE_EXISTS" != "" ]; then
        echo "✅ $ROLE"
    else
        echo "❌ $ROLE non trouvé"
    fi
done
echo ""

echo "🔍 6. KUBERNETES - NODES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get nodes 2>/dev/null || echo "❌ Impossible de se connecter au cluster"
echo ""

echo "🔍 7. KUBERNETES - PODS (Running)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get pods -n default --field-selector=status.phase=Running 2>/dev/null || echo "❌ Impossible de lister les pods"
echo ""

echo "🔍 8. KUBERNETES - SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl get svc -n default 2>/dev/null || echo "❌ Impossible de lister les services"
echo ""

echo "🔍 9. LOAD BALANCERS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}' --output table 2>/dev/null || echo "❌ Aucun load balancer trouvé"
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    RÉSUMÉ                                 ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📊 État général:"
NODES_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
PODS_RUNNING=$(kubectl get pods -n default --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')
PODS_TOTAL=$(kubectl get pods -n default --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "   - Nodes actifs: $NODES_COUNT"
echo "   - Pods en cours d'exécution: $PODS_RUNNING"
echo "   - Total des pods: $PODS_TOTAL"
echo ""

