#!/bin/bash
set -x
sudo yum install -y docker
sudo usermod -aG docker $USER
newgrp docker

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

sudo reboot

sudo systemctl start docker
sudo systemctl status docker
