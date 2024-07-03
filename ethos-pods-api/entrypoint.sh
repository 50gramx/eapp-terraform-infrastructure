#!/bin/bash

# Function to start SSH port forwarding
start_port_forwarding() {
  ssh -i settings/openvpn -N -L 16443:13.200.238.161:16443 ec2-user@13.200.238.161 -v &
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
