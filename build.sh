#!/bin/bash
set -e

# Overwrite HOME to WORKSPACE
export HOME="$WORKSPACE"

# Install gpuCI tools
rm -rf .gpuci
git clone https://github.com/rapidsai/gpuci-tools.git .gpuci
chmod +x .gpuci/tools/*
export PATH="$PWD/.gpuci/tools:$PATH"

# Show env
gpuci_logger "Exposing current environment..."
env

# Login to docker
gpuci_logger "Logging into Docker..."
echo $DH_TOKEN | docker login --username $DH_USER --password-stdin &> /dev/null

gpuci_logger "Build runtime image..."
docker build --squash -t gpuci/cuda-l4t:10.2-runtime-ubuntu18.04 -f runtime/Dockerfile runtime/

# List image info
gpuci_logger "Displaying runtime image info..."
docker images gpuci/cuda-l4t:10.2-runtime-ubuntu18.04

# Upload image
gpuci_logger "Starting upload..."
GPUCI_RETRY_MAX=5
GPUCI_RETRY_SLEEP=120
gpuci_retry docker push gpuci/cuda-l4t:10.2-runtime-ubuntu18.04

gpuci_logger "Build devel image..."
docker build --squash -t gpuci/cuda-l4t:10.2-devel-ubuntu18.04 -f devel/Dockerfile devel/

# List image info
gpuci_logger "Displaying devel image info..."
docker images gpuci/cuda-l4t:10.2-devel-ubuntu18.04

# Upload image
gpuci_logger "Starting upload..."
GPUCI_RETRY_MAX=5
GPUCI_RETRY_SLEEP=120
gpuci_retry docker push gpuci/cuda-l4t:10.2-devel-ubuntu18.04

# Logout of docker
gpuci_logger "Logout of Docker..."
docker logout

# Clean up build
gpuci_logger "Clean up docker builds on system..."
docker system df
docker system prune --volumes -f
docker system df
