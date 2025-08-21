#!/bin/bash

argocd login --insecure --grpc-web localhost:8081

kubectl config use-context k3d-dev && argocd cluster add k3d-dev
kubectl config use-context k3d-prod && argocd cluster add k3d-prod
kubectl config use-context k3d-stage && argocd cluster add k3d-stage


kubectl config use-context k3d-mycluster