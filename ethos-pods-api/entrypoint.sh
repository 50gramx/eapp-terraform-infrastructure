#!/bin/bash

# Function to update file permissions and start SSH port forwarding
start_port_forwarding() {
  # Update permissions of settings/openvpn to 600
  chmod 600 settings/openvpn

  # Start SSH port forwarding with updated permissions
  ssh -i settings/openvpn -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -N -L 16443:13.200.238.161:16443 ec2-user@13.200.238.161 -v &
  SSH_PID=$!
}

# Start port forwarding
start_port_forwarding

# Function to check if the port forwarding process is running
check_port_forwarding() {
  if ! kill -0 $SSH_PID > /dev/null 2>&1; then
    echo "Port forwarding process has stopped. Restarting..."
    start_port_forwarding
  fi
}

# Start the server in the background
python ethos-pods-api/main.py &

# Server process PID
SERVER_PID=$!

# Infinite loop to monitor the port forwarding process
while true; do
  check_port_forwarding
  sleep 10
done
