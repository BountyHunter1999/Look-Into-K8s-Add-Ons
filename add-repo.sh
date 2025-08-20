#!/bin/bash

# Prompt for repository URL
read -p "Enter repo URL: " repo_url

# Prompt for username
read -p "Enter repo username: " username

# Prompt for password (hidden input)
read -s -p "Enter repo password: " password
echo

argocd login --insecure --grpc-web localhost:8081

argocd repo add $repo_url --username $username --password $password
