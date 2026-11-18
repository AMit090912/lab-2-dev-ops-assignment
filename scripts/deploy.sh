#!/usr/bin/env bash
# Continuous deployment step (used by the GitHub Actions pipeline and locally):
# build the image inside Minikube, apply the manifests, roll out the new tag and smoke-test it.
# Usage: scripts/deploy.sh [image-tag] [app-version]
set -euo pipefail

TAG="${1:-$(git rev-parse --short HEAD)}"
VERSION="${2:-$TAG}"
IMAGE="lab2-app:${TAG}"

echo "==> Building ${IMAGE} inside the Minikube Docker daemon"
eval "$(minikube docker-env)"
docker build -q --build-arg APP_VERSION="${VERSION}" -t "${IMAGE}" .

echo "==> Applying Kubernetes manifests with image ${IMAGE}"
kubectl apply -f k8s/service.yaml
sed "s|image: lab2-app:.*|image: ${IMAGE}|" k8s/deployment.yaml | kubectl apply -f -
kubectl annotate deployment/lab2-app kubernetes.io/change-cause="CD deploy ${IMAGE}" --overwrite

echo "==> Waiting for the rolling update"
kubectl rollout status deployment/lab2-app --timeout=120s

echo "==> Smoke test (inside the cluster, through the Service DNS name)"
kubectl run smoke-test --rm -i --quiet --restart=Never --image=busybox:1.36 -- wget -qO- http://lab2-app/health
echo
