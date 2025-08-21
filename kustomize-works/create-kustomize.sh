#!/bin/bash

read -p "Enter the name of the kustomize app: " app_name

envs=("dev" "stage" "prod")

if [ -d "$app_name" ]; then
    echo "Directory $app_name already exists"
    exit 1
fi

if [ -z "$app_name" ]; then
    echo "App name is required"
    exit 1
fi


mkdir -p $app_name/base

cat <<EOF > $app_name/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deploy.yaml
  - svc.yaml

commonLabels:
  company: happy_corp
  app: $app_name

commonAnnotations:
  description: "This is a test deployment"
EOF

kubectl create deployment ${app_name}-deploy --image=nginx:latest --dry-run=client -o yaml > $app_name/base/deploy.yaml
kubectl create service clusterip ${app_name}-svc --tcp=80:80 --dry-run=client -o yaml > $app_name/base/svc.yaml

for env in "${envs[@]}"; do
    mkdir -p $app_name/overlays/$env
    cat <<EOF > $app_name/overlays/$env/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

secretGenerator:
    - name: ${app_name}-env
      literals:
        - APP_ENV=${env}

namespace: ${app_name}-${env}A

images:
  - name: nginx
    newTag: latest

patches:
  - target:
      kind: Deployment
      name: ${app_name}-deploy
    patch: |-
      - op: add
        path: /spec/template/spec/tolerations
        value:
          - key: env
            operator: Equal
            value: ${env}
            effect: NoSchedule
EOF
done

echo "Kustomize app $app_name created"