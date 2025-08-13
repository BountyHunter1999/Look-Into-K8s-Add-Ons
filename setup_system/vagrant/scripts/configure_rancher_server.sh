#!/bin/bash -x

rancher_ip="192.168.56.101"
admin_password=${1:-password}
rancher_version=${2:-stable}
k8s_version=$3
curlimage="appropriate/curl:latest"
jqimage="stedolan/jq:latest"

# Update system and install certificates
sudo update-ca-certificates

# Fix SSL certificate issues by updating CA certificates
# This is often the root cause of Docker pull certificate errors
# sudo ros config set rancher.docker.tls true
# sudo ros config set rancher.system_docker.tls true

# # Update CA certificates in the system
# sudo ros config set rancher.ca_certs true
# sudo ros config set rancher.system_ca_certs true

# # Alternative approach: Configure Docker to use system CA certificates
# sudo ros config set rancher.docker.ca_certs true
# sudo ros config set rancher.system_docker.ca_certs true

# # Restart Docker services to apply changes
# sudo system-docker restart docker
# sleep 10

# Try to pull images with retry logic
for image in $curlimage $jqimage "rancher/rancher:${rancher_version}"; do
  echo "Pulling image: $image"
  retry_count=0
  max_retries=5
  
  until docker inspect $image > /dev/null 2>&1; do
    if [ $retry_count -ge $max_retries ]; then
      echo "Failed to pull $image after $max_retries attempts"
      # Try alternative approach: use system-docker
      echo "Trying with system-docker..."
      sudo system-docker pull $image || true
      
      # If still failing, try to copy from system-docker to user docker
      if sudo system-docker inspect $image > /dev/null 2>&1; then
        echo "Image found in system-docker, copying to user docker..."
        sudo system-docker save $image | docker load || true
      fi
      break
    fi
    
    # Try pulling with different approaches
    docker pull $image
    
    retry_count=$((retry_count + 1))
    echo "Retry $retry_count of $max_retries for $image"
    sleep 2
  done
  echo "Successfully pulled $image"
done

docker run -d --restart=unless-stopped -p 80:80 -p 443:443 -v /opt/rancher:/var/lib/rancher --privileged rancher/rancher:${rancher_version}

# wait until rancher server is ready
while true; do
  docker run --rm --net=host $curlimage -sLk https://127.0.0.1/ping && break
  sleep 5
done

# Check if there's a bootstrap password in the log
CONTAINERID=$(docker ps | grep "rancher/rancher:${rancher_version}" | cut -d " " -f 1)
BOOTSTRAP_PASSWORD=$(docker logs "$CONTAINERID" 2>&1 | grep "Bootstrap Password:" | sed -n 's/.*: \(.*\)$/\1/p')
if [ -z "$BOOTSTRAP_PASSWORD" ]; then
    BOOTSTRAP_PASSWORD="admin"
fi

# Login
while true; do
    LOGINRESPONSE=$(docker run \
        --rm \
        --net=host \
        $curlimage \
        -s "https://127.0.0.1/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"'$BOOTSTRAP_PASSWORD'"}' --insecure)
    LOGINTOKEN=$(echo $LOGINRESPONSE | docker run --rm -i $jqimage -r .token)

    if [ "$LOGINTOKEN" != "null" ]; then
        break
    else
        sleep 5
    fi
done


# Change password
docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/users?action=changepassword' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"currentPassword":"'$BOOTSTRAP_PASSWORD'","newPassword":"'$admin_password'"}' --insecure

# Create API key
APIRESPONSE=$(docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/token' -H 'content-type: application/json' -H "Authorization: Bearer $LOGINTOKEN" --data-binary '{"type":"token","description":"automation"}' --insecure)

# Extract and store token
APITOKEN=`echo $APIRESPONSE | docker run --rm -i $jqimage -r .token`

# Configure server-url
RANCHER_SERVER="https://${rancher_ip}"
docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/settings/server-url' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" -X PUT --data-binary '{"name":"server-url","value":"'$RANCHER_SERVER'"}' --insecure

while true; do
  docker run --rm --net=host $curlimage -sLk https://127.0.0.1/ping && break
  sleep 5
done

# Test if cluster is created or retry
while true; do
  # Create cluster
  CLUSTERRESPONSE=$(docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/cluster' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"dockerRootDir":"/var/lib/docker","enableNetworkPolicy":false,"type":"cluster","rancherKubernetesEngineConfig":{"kubernetesVersion":"'$k8s_version'","addonJobTimeout":30,"ignoreDockerVersion":true,"sshAgentAuth":false,"type":"rancherKubernetesEngineConfig","authentication":{"type":"authnConfig","strategy":"x509"},"network":{"options":{"flannelBackendType":"vxlan"},"plugin":"canal","canalNetworkProvider":{"iface":"eth1"}},"ingress":{"type":"ingressConfig","provider":"nginx"},"monitoring":{"type":"monitoringConfig","provider":"metrics-server"},"services":{"type":"rkeConfigServices","kubeApi":{"podSecurityPolicy":false,"type":"kubeAPIService"},"etcd":{"creation":"12h","extraArgs":{"heartbeat-interval":500,"election-timeout":5000},"retention":"72h","snapshot":false,"type":"etcdService","backupConfig":{"enabled":true,"intervalHours":12,"retention":6,"type":"backupConfig"}}}},"localClusterAuthEndpoint":{"enabled":true,"type":"localClusterAuthEndpoint"},"name":"quickstart"}' --insecure)
  # Extract clusterid to use for generating the docker run command
  CLUSTERID=`echo $CLUSTERRESPONSE | docker run --rm -i $jqimage -r .id`
  if [ -n "$CLUSTERID" ]; then
    break
  else
    sleep 5
  fi
done

# Generate registrationtoken
docker run --rm --net=host $curlimage -s 'https://127.0.0.1/v3/clusterregistrationtoken' -H 'content-type: application/json' -H "Authorization: Bearer $APITOKEN" --data-binary '{"type":"clusterRegistrationToken","clusterId":"'$CLUSTERID'"}' --insecure