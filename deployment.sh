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

    # Clone and dockerize app
    git clone https://github.com/maximweiss57/flask-for-monitoring-.git ~/flask-for-monitoring || handle_error "Failed to clone Flask application repository"
    docker build -t flask-for-monitoring-image ~/flask-for-monitoring || handle_error "Failed to build Flask application Docker image"

    # Pull Mongo image
    docker pull mongo:4 || handle_error "Failed to pull Mongo image"

    log "Dependencies installed successfully"
}

create_cluster() {
    log "Creating KinD cluster"
    kind create cluster --name monitoring-cluster || handle_error "Failed to create KinD cluster"
    log "KinD cluster created successfully"
}

Load_image_to_cluster(){
    kind load docker-image flask-for-monitoring-image --name monitoring-cluster
}
# Function to deploy single MongoDB instance
deploy_single_mongodb() {
    log "Deploying single MongoDB instance"
    kubectl apply -f ~/flask-for-monitoring/yamls/mongodb-single.yaml || handle_error "Failed to deploy single MongoDB instance"
    log "Single MongoDB instance deployed successfully"
}

# Function to deploy MongoDB cluster
deploy_mongodb_cluster() {
    log "Deploying MongoDB cluster"
    # Create MongoDB replica set configuration
    kubectl apply -f ~/flask-for-monitoring/yamls/mongodb-cluster-config.yaml || handle_error "Failed to create MongoDB replica set configuration"
    # Create MongoDB deployment and service
    kubectl apply -f ~/flask-for-monitoring/yamls/mongodb-cluster.yaml || handle_error "Failed to deploy MongoDB cluster"
    log "MongoDB cluster deployed successfully"
}

deploy_app() {
    log "Deploying Flask application"
    kubectl apply -f ~/flask-for-monitoring/yamls/flask-app.yaml || handle_error "Failed to deploy Flask application"
    log "Flask application deployed successfully"
}

read -p "Do you want to deploy a single MongoDB instance or a MongoDB cluster? (single/cluster) " mongodb_deployment


install_dependencies
create_cluster
Load_image_to_cluster

# Deploy MongoDB based on user's choice
if [ "$mongodb_deployment" = "single" ]; then
    deploy_single_mongodb
elif [ "$mongodb_deployment" = "cluster" ]; then
    deploy_mongodb_cluster
else
    handle_error "Invalid MongoDB deployment choice"
fi

deploy_app

# Expose Flask application with external IP
log "Exposing Flask application with external IP"
kubectl apply -f ~/flask-for-monitoring/yamls/flask-app-service.yaml || handle_error "Failed to create Flask app service"
external_ip=$(kubectl get service flask-app-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
log "The deployment is complete, Flask application is accessible at http://$external_ip"
echo "The deployment is complete, Flask application is accessible at http://$external_ip"
