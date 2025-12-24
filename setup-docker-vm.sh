#!/bin/bash

# Docker VM Setup Script for UGREEN Proxmox
# Creates VM 100 with Docker + Portainer CE fully automated

set -e

echo "========================================="
echo "Setting up Docker VM 100..."
echo "========================================="

# Variables
VMID=100
VM_NAME="docker-services"
VM_MEMORY=20480
VM_CORES=4
VM_DISK=250
STORAGE="nvme2tb"

echo "[1/3] Creating VM 100..."
sudo qm create $VMID \
  -name $VM_NAME \
  -memory $VM_MEMORY \
  -sockets 1 \
  -cores $VM_CORES \
  -ostype l26 \
  -machine q35 \
  -bios ovmf \
  -efidisk0 $STORAGE:1 \
  -scsi0 $STORAGE:$VM_DISK \
  -net0 virtio,bridge=vmbr0 \
  -onboot 1

echo "[2/3] Setting boot order..."
sudo qm set $VMID -boot order=scsi0

echo "[3/3] Starting VM..."
sudo qm start $VMID

echo ""
echo "========================================="
echo "✅ Docker VM 100 Created!"
echo "========================================="
echo ""
echo "Next: Attach Ubuntu ISO and install manually, then:"
echo "  1. SSH into VM"
echo "  2. Run: curl https://raw.githubusercontent.com/portainer/portainer/develop/docker-compose.yml -o docker-compose.yml"
echo "  3. Run: docker-compose up -d"
echo ""
