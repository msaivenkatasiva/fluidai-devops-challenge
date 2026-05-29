#!/bin/bash
set -e

# Variables
CLUSTER_NAME=fluid-devops
REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "Updating kube-config"
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

echo "Associating OIDC Provider"
eksctl utils associate-iam-oidc-provider \
  --cluster $CLUSTER_NAME \
  --region $REGION \
  --approve

echo "Downloading IAM policy"
curl -s -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

echo "Creating IAM policy"
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json || true

echo "Creating IAM ServiceAccount"
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve \
  --region $REGION

echo "Installing AWS Load Balancer Controller"
helm repo add eks https://aws.github.io/eks-charts
helm repo update

VPC_ID=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

echo "VPC ID: $VPC_ID"

helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set region=$REGION \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set vpcId=$VPC_ID

echo "Waiting for controller to start"
kubectl wait \
  --for=condition=available \
  deployment/aws-load-balancer-controller \
  -n kube-system \
  --timeout=120s

echo "Checking ALB Controller status"
kubectl get deployment aws-load-balancer-controller -n kube-system

echo ""
echo "Controller Pods:"
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

echo "Creating namespace"
kubectl apply -f k8s/namespace.yaml
echo "Namespace fluid-app created!"

echo "ALB Controller Setup Completed Successfully!"
echo "Next Steps:"
echo "Deploy Redis:"
echo "kubectl apply -f k8s/redis.yaml"
echo "Deploy Flask App:"
echo "kubectl apply -f k8s/deployment.yaml"
echo "Deploy Service:"
echo "kubectl apply -f k8s/service.yaml"
echo "Deploy Ingress:"
echo "kubectl apply -f k8s/ingress.yaml"
echo "Get ALB URL:"
echo "kubectl get ingress flask-ingress"