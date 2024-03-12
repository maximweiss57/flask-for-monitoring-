#!/bin/bash

# Function to log messages
log() {
    if ! test -d /var/log/flask-monitoring; then
        mkdir -p /var/log/flask-monitoring
    fi
    local message="$1"
    local log_file="/var/log/flask-monitoring/deployment_$(date +'%Y%m%d_%H%M%S').log"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $message" >> "$log_file"
}

# Function to handle errors
handle_error() {
    local error_message="$1"
    log "Error: $error_message"
    echo "An error occurred: $error_message"
    exit 1
}

install_dependencies() {
    log "Installing dependencies"
    
    # Install and start Docker
    dnf -y install dnf-plugins-core || handle_error "Failed to install dnf-plugins-core"
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo || handle_error "Failed to add Docker repository"
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || handle_error "Failed to install Docker packages"
    systemctl start docker || handle_error "Failed to start Docker service"
    systemctl enable docker || handle_error "Failed to enable Docker service"
    docker run hello-world || handle_error "Docker installation test failed"

    # Install KinD
    curl -Lo kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64 || handle_error "Failed to download KinD"
    chmod +x ./kind || handle_error "Failed to make KinD executable"
    sudo mv ./kind /usr/local/bin/kind || handle_error "Failed to move KinD to /usr/local/bin"

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" || handle_error "Failed to download kubectl"

    # Install Helm
    dnf install -y helm || handle_error "Failed to install Helm"

    # Clone app
    git clone https://github.com/maximweiss57/flask-for-monitoring-.git ~/flask-for-monitoring || handle_error "Failed to clone Flask application repository"
    docker pull hixs/monitoring_app:latest || handle_error "Failed to pull Flask application Docker image"
    # Pull Mongo image
    docker pull mongo:4 || handle_error "Failed to pull Mongo image"

    log "Dependencies installed successfully"
}

create_cluster() {
    # Downloading kind cluster configuration
    wget https://gist.githubusercontent.com/purushothamkdr453/39e097ce8ea62efbf28d8badebcbf5dd/raw/eab80fba4afdab26a3a9398d5ba59d383aad27ae/kind-single-controlplane-multiple-worker.yaml
# Creating kind kubernetes cluster 
    kind create cluster --config kind-single-controlplane-multiple-worker.yaml
}
create_namespace() {
    kubectl apply -f ~/flask-for-monitoring/yamls/namespace.yaml || handle_error "Failed to create monitoring namespace"
}
mongo_db(){
    kubectl apply -f ~/flask-for-monitoring/yamls/mongo-pv.yaml || handle_error "Failed to deploy MongoDB"
    kubectl apply -f ~/flask-for-monitoring/yamls/mongo-pvc.yaml || handle_error "Failed to create MongoDB service"
    kubectl apply -f ~/flask-for-monitoring/yamls/mongo-secrets.yaml || handle_error "Failed to install MongoDB secrets"
    kubectl apply -f ~/flask-for-monitoring/yamls/mongo-statefull.yaml || handle_error "Failed to install MongoDB statefulset"
    kubectl apply -f ~/flask-for-monitoring/yamls/mongo-svc.yaml || handle_error "Failed to install MongoDB service"
}
deploy_app() {
    log "Deploying Flask application"
    kubectl apply -f ~/flask-for-monitoring/yamls/flask-app.yaml || handle_error "Failed to deploy Flask application"
    kubectl apply -f ~/flask-for-monitoring/yamls/flask-app-service.yaml || handle_error "Failed to create Flask app service"
    kubectl apply -f ~/flask-for-monitoring/yamls/ingress.yaml || handle_error "Failed to install Ingress"
    log "Flask application deployed successfully"
}

install_metalLB(){
    #Install MetalLB
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml || handle_error "Failed to install MetalLB"
    kubectl wait --for=condition=available --timeout=600s deployment/controller -n metallb-system || handle_error "Failed to install MetalLB"
    kubectl apply -f ~/flask-for-monitoring/yamls/metalLB.yaml || handle_error "Failed to install MetalLB"
}

install_ingress(){
    # Download the Nginx-Ingress Helm chart from the OCI registry and extract it
    helm pull oci://ghcr.io/nginxinc/charts/nginx-ingress --untar --version 1.1.3
    # Apply Custom Resource Definitions (CRDs) required by Nginx-Ingress
    kubectl apply -f nginx-ingress/crds/
    # Install Nginx-Ingress using Helm
    helm install nginx-ingress oci://ghcr.io/nginxinc/charts/nginx-ingress --version 1.1.3
}

# Get the external IP of the cluster and edit /etc/hosts
get_ip() {
external_ip=$(kubectl get svc mongo-db -n survey-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
}

install_dependencies 
create_cluster
create_namespace
mongo_db
install_metalLB
install_ingress
deploy_app
get_ip
log "The deployment is complete, Flask application is accessible at http://$external_ip"
echo "The deployment is complete, Flask application is accessible at http://$external_ip"
