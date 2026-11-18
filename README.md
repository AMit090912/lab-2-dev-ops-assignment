# Lab 2: Containerization & Kubernetes Orchestration

**Name:** Amit · **Roll No.:** 2301010471

A small Flask app is containerized with Docker, run with Docker Compose (app + Redis), and deployed to a
Minikube Kubernetes cluster with rolling updates, rollbacks, scaling and a CI/CD pipeline.

## Structure

```
app/app.py, app/requirements.txt   Flask app (version, pod name, Redis visit counter)
Dockerfile, .dockerignore          image definition
docker-compose.yml                 web + redis, named volume, custom network
k8s/deployment.yaml                Deployment (3 replicas, RollingUpdate, probes, limits)
k8s/service.yaml                   NodePort Service (port 30080)
scripts/deploy.sh                  CD step: build image in Minikube, apply manifests, roll out, smoke test
.github/workflows/cd.yml           CI/CD: build + test image, then deploy to Minikube
```

## Docker

```bash
docker build -t lab2-app:1.0 .
docker run -d --name lab2 -p 8000:5000 lab2-app:1.0
curl localhost:8000/health
docker compose up -d --build        # app + redis on http://localhost:8000
```

## Kubernetes (Minikube)

```bash
minikube start --driver=docker --container-runtime=docker
eval $(minikube docker-env) && docker build -t lab2-app:1.0 .
kubectl apply -f k8s/
kubectl get deploy,pods,svc
curl http://$(minikube ip):30080/health

# rolling update, rollback, scaling
kubectl set image deployment/lab2-app lab2-app=lab2-app:2.0
kubectl rollout status deployment/lab2-app
kubectl rollout undo deployment/lab2-app
kubectl scale deployment/lab2-app --replicas=5
```

## Continuous deployment

`scripts/deploy.sh` builds an image tagged with the git commit, applies `k8s/`, updates the Deployment and waits
for the rollout. The GitHub Actions workflow runs it on every push to `main`.
