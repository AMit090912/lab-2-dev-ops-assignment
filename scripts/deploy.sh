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

echo "==> Applying Kubernetes manifests"
kubectl apply -f k8s/

echo "==> Rolling out ${IMAGE}"
kubectl set image deployment/lab2-app lab2-app="${IMAGE}"
kubectl annotate deployment/lab2-app kubernetes.io/change-cause="CD deploy ${IMAGE}" --overwrite
kubectl rollout status deployment/lab2-app --timeout=120s

echo "==> Smoke test"
URL="$(minikube service lab2-app --url)"
curl -fsS "${URL}/health"
echo
