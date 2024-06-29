#!/bin/bash

wget -O /etc/yum.repos.d/snapd.repo \
    https://bboozzoo.github.io/snapd-amazon-linux/amzn2/snapd.repo

yum install snapd -y

systemctl enable --now snapd.socket

# Function to check if snapd is initialized
check_snap_initialized() {
    # Wait for the snap system to be ready
    local retries=10
    local wait_time=10
    
    for ((i=1; i<=retries; i++)); do
        # Check the system seed status
        seed_status=$(snap changes | grep "seed")

        if [ -z "$seed_status" ]; then
            echo "Snap system is initialized."
            return 0
        else
            echo "Snap system is not initialized yet. Retrying in $wait_time seconds... ($i/$retries)"
            sleep $wait_time
        fi
    done
    
    echo "Snap system failed to initialize after $retries attempts."
    return 1
}

# Function to install MicroK8s
install_microk8s() {
    echo "Installing MicroK8s..."
    sudo snap install microk8s --classic
    echo " MicroK8s installation done..."
    echo " Usermod command"

    sudo -i usermod -a -G microk8s $USER
    echo " Usermod command done"
    echo " .kube dir creation"

    mkdir -p ~/.kube

    chmod 0700 ~/.kube
    echo " .kube owning"

    sudo chown -R ec2-user ~/.kube
    echo " .kube owning Done"
    echo " newgrp command"

    sudo sg microk8s -c 'echo New group applied: $(groups)'

    echo "newgrp command done"
    echo "microk8s command start"

    export PATH=$PATH:/var/lib/snapd/snap/bin
    
    microk8s start

    echo "microk8s command done"


    if [ $? -eq 0 ]; then
        echo "MicroK8s installed successfully."
    else
        echo "Failed to install MicroK8s."
        exit 1
    fi
}

# Main script execution
echo "Checking if Snap is initialized..."
if check_snap_initialized; then
    install_microk8s
else
    echo "Snap system initialization failed. Cannot proceed with MicroK8s installation."
    exit 1
fi
