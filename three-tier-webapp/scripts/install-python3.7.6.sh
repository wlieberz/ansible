#!/usr/bin/env bash

cd ~/

mkdir python37-build

# Download
cd python37-build/
wget https://www.python.org/ftp/python/3.7.6/Python-3.7.6.tar.xz

# Unzip
tar -xf Python-3.7.6.tar.xz 
cd Python-3.7.6

# Configure:
./configure --prefix=/opt/python37 --enable-optimizations

# Build:
make

# Install:
sudo make altinstall

# Clean-up:
cd ~/
rm -rf ~/python37-build

# Verify
PATH=$PATH:/opt/python37/bin
python3.7 --version

# Add globally to path, for bash:
echo 'PATH=$PATH:/opt/python37/bin' | sudo tee /etc/profile.d/python37-path-bash.sh
