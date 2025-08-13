#!/bin/bash -x
rancher_server_ip=${1:-192.168.56.101}
admin_password=${2:-password}
curlimage="appropriate/curl:latest"
jqimage="stedolan/jq:latest"
enabled_iscsi=${3:-"disabled"}

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

agent_ip=`ip addr show eth1 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1`
echo $agent_ip `hostname` >> /etc/hosts

for image in $curlimage $jqimage; do
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
    sleep 5
  done
  echo "Successfully pulled $image"
done

while true; do
  docker run --rm $curlimage -sLk https://$rancher_server_ip/ping && break
  sleep 5
done

# Login
while true; do

    LOGINRESPONSE=$(docker run \
        --rm \
        $curlimage \
        -s "https://$rancher_server_ip/v3-public/localProviders/local?action=login" -H 'content-type: application/json' --data-binary '{"username":"admin","password":"'$admin_password'"}' --insecure)
    LOGINTOKEN=$(echo $LOGINRESPONSE | docker run --rm -i $jqimage -r .token)

    if [ "$LOGINTOKEN" != "null" ]; then
        break
    else
        sleep 5
    fi
done

# Test if cluster is created
while true; do
  CLUSTERID=$(docker run \
    --rm \
    $curlimage \
      -sLk \
      -H "Authorization: Bearer $LOGINTOKEN" \
      "https://$rancher_server_ip/v3/clusters?name=quickstart" | docker run --rm -i $jqimage -r '.data[].id')

  if [ -n "$CLUSTERID" ]; then
    break
  else
    sleep 5
  fi
done

if [ `hostname` == "node-01" ]; then
  ROLEFLAGS="--etcd --controlplane --worker"
else
  #ROLEFLAGS="--worker"
  ROLEFLAGS="--worker"
fi

# Get token
# Test if cluster is created
while true; do
  AGENTCMD=$(docker run \
    --rm \
    $curlimage \
      -sLk \
      -H "Authorization: Bearer $LOGINTOKEN" \
      "https://$rancher_server_ip/v3/clusterregistrationtoken?clusterId=$CLUSTERID" | docker run --rm -i $jqimage -r '.data[].nodeCommand' | head -1)

  if [ -n "$AGENTCMD" ]; then
    break
  else
    sleep 5
  fi
done

# Show the command
COMPLETECMD="$AGENTCMD $ROLEFLAGS --internal-address $agent_ip --address $agent_ip "
$COMPLETECMD

if [ "$enabled_iscsi" = "enabled" ] ; then
# Enable iscsi, stat and flock
  sudo wget https://busybox.net/downloads/binaries/1.31.0-i686-uclibc/busybox_STAT -O /bin/stat
  sudo wget https://busybox.net/downloads/binaries/1.31.0-i686-uclibc/busybox_FLOCK -O /bin/flock
  sudo chmod +x /bin/stat
  sudo chmod +x /bin/flock
  sudo ros s enable open-iscsi
  sudo ros s up open-iscsi
fi