import re
from datetime import datetime, timedelta

import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from kubernetes import client, config
import json

app = Flask(__name__)
CORS(app)  # This will enable CORS for all routes

# Load the Kubernetes configuration
config.load_kube_config(config_file='ethos-pods-api/microk8s-config')  # This assumes you have a kubeconfig file set up

# Create a Kubernetes API client
v1 = client.CoreV1Api()

# List all pods in the default namespace
try:
    # List all pods and services in the default namespace
    pods = v1.list_namespaced_pod(namespace="default")
    services = v1.list_namespaced_service(namespace="default")
    nodes = v1.list_node()

    # Extract public IP of the master node
    master_node_ip = "13.200.238.161"

        # Ensure we have the master node's public IP
    if not master_node_ip:
        print(jsonify({"error": "Master node public IP not found"}))

    # Map service names to NodePorts
    service_ports = {}
    for service in services.items:
        if service.spec.type == 'NodePort':
            node_ports = []
            # Iterate through the ports and collect NodePort details
            for port in service.spec.ports:
                node_ports.append({
                    'port': port.port,
                    'node_port': port.node_port
                })
            # Add the service to the mapping if the app matches
            service_ports[service.metadata.name] = node_ports
    print(f"service_ports: {service_ports}")

    pod_list = []
    for pod in pods.items:
        print(f"labels: {pod.metadata.labels}")
        pod_name = pod.metadata.labels.get("app", "")
        node_name = pod.spec.node_name
        expiration_time = pod.metadata.annotations.get("expiration-time")
        print(f"checking for pod: {pod_name}")

        # Check if a corresponding NodePort service exists for the pod
        if pod_name in service_ports:
            print(f"found pod {pod_name} in service ports")
            # Use the first NodePort (you can modify this if there are multiple ports)
            node_port = service_ports[pod_name][0]['node_port']
            access_url = f"http://{master_node_ip}:{node_port}"
        else:
            access_url = None

        pod_info = {
            "name": pod_name,
            "namespace": pod.metadata.namespace,
            "node_name": node_name,
            "status": pod.status.phase,
            "start_time": pod.status.start_time,
            "ssh_command": access_url,  # This is the URL for accessing the service
            "scheduled_deletion_time": expiration_time
        }
        print(pod_info)
        pod_list.append(pod_info)
        
    print(pod_list)
except client.exceptions.ApiException as e:
    print(jsonify({"error": str(e)}))