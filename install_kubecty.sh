#!/bin/bash

# Function to check if a command was successful
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed"
    exit 1
  fi
}

# Function to ensure Docker is running
ensure_docker_running() {
  sudo systemctl start docker
  check_success "Starting Docker"
}

# Function to disable SELinux
disable_selinux() {
  sudo setenforce 0
  check_success "Disabling SELinux"
  sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
  check_success "Setting SELINUX to permissive"
}

# Update the system
echo "Updating system..."
sudo apt-get update
check_success "System update"

# Install necessary packages
echo "Installing necessary packages..."
sudo apt-get install -y apt-transport-https ca-certificates curl
check_success "Installing necessary packages"

# Download the Google Cloud public signing key
echo "Downloading Google Cloud public signing key..."
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
check_success "Downloading Google Cloud public signing key"

# Add the Kubernetes APT repository
echo "Adding Kubernetes APT repository..."
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
check_success "Adding Kubernetes APT repository"

# Update package list again
echo "Updating package list..."
sudo apt-get update
check_success "Updating package list"

# Install kubectl
echo "Installing kubectl..."
sudo apt-get install -y kubectl
check_success "Installing kubectl"

# Download the Minikube binary
echo "Downloading Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
check_success "Downloading Minikube"

# Install Minikube
echo "Installing Minikube..."
sudo install minikube-linux-amd64 /usr/local/bin/minikube
check_success "Installing Minikube"

# Clean up the downloaded Minikube binary
rm minikube-linux-amd64

# Ensure Docker is running
ensure_docker_running

# Start Minikube with Docker driver
echo "Starting Minikube..."
minikube start --driver=docker --memory=4096 --cpus=2
if [ $? -ne 0 ]; then
  echo "Minikube failed to start, attempting to disable SELinux and retrying..."
  disable_selinux
  minikube start --driver=docker --memory=4096 --cpus=2
  check_success "Starting Minikube after disabling SELinux"
fi

# Verify installation
echo "Verifying installation..."
kubectl get nodes
check_success "Verifying installation"

# Test Minikube and kubectl
echo "Testing Minikube and kubectl..."

# Check Minikube status
minikube status | grep -E 'host: Running|kubelet: Running|apiserver: Running|kubeconfig: Configured' > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: Minikube is not running properly. Please check the logs and try again."
    exit 1
fi

# Check kubectl version
kubectl version --client
if [ $? -ne 0 ]; then
    echo "Error: kubectl is not running properly. Ensure it is installed correctly and try again."
    exit 1
fi

echo "Minikube and kubectl are successfully installed and running!"
