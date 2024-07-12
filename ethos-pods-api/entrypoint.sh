#!/bin/bash

# Function to update file permissions and start SSH port forwarding
start_port_forwarding() {
  # Update permissions of settings/openvpn to 600
  chmod 600 /app/settings/openvpn || exit 1

  # Start SSH port forwarding with updated permissions
  ssh -i /app/settings/openvpn -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -N -L 16443:13.200.238.161:16443 ec2-user@13.200.238.161 -v &
  SSH_PID=$!
}

# Function to check if the port forwarding process is running
check_port_forwarding() {
  if ! kill -0 $SSH_PID > /dev/null 2>&1; then
    echo "Port forwarding process has stopped. Restarting..."
    start_port_forwarding
  fi
}

# Function to start Gunicorn with HTTPS
start_gunicorn() {
  gunicorn --certfile=$SSL_CERT --keyfile=$SSL_KEY -b 0.0.0.0:8000 ethos-pods-api.main:app &
  GUNICORN_PID=$!
}

# Start port forwarding
start_port_forwarding

# Start Gunicorn server with HTTPS
start_gunicorn

# Trap signals for graceful shutdown (optional but recommended)
trap 'echo "Received signal, stopping processes..." && kill $SSH_PID $GUNICORN_PID; exit 0' SIGTERM SIGINT

# Infinite loop to monitor the processes
while true; do
  check_port_forwarding
  if ! kill -0 $GUNICORN_PID > /dev/null 2>&1; then
    echo "Gunicorn process has stopped. Restarting..."
    start_gunicorn
  fi
  sleep 10
done
