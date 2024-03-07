#!/bin/bash 
# Function to log messages
log() {
    file -d /var/log/flask-monitoring
    if $? -ne 0; then
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