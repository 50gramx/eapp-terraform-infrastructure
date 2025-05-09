import re
from datetime import datetime, timedelta

import requests
from flask import Flask, request, jsonify
from flask_cors import CORS
from kubernetes import client, config

app = Flask(__name__)
CORS(app)  # This will enable CORS for all routes

# Load the Kubernetes configuration
config.load_kube_config(config_file='/app/ethos-pods-api/microk8s-config')  # This assumes you have a kubeconfig file set up


@app.route('/create_pod', methods=['POST'])
def create_pod():
    data = request.get_json()

    # Validate input
    required_keys = ['name', 'image', 'container_ports']
    if not all(key in data for key in required_keys):
        return jsonify({"error": "Missing required fields"}), 400

    name = data['name']
    image = data['image']
    container_ports = data['container_ports']  # List of ports
    env_vars = data.get('env', [])  # Optional environment variables
    expiration_time = (datetime.utcnow() + timedelta(hours=1)).isoformat("T") + "Z"  # ISO 8601 format

    # Ensure the name follows DNS-1035 label rules
    if not re.match(r'^[a-z]([-a-z0-9]*[a-z0-9])?$', name):
        return jsonify({
            "error": "Invalid pod name. Must consist of lower case alphanumeric characters or '-', start with an alphabetic character, and end with an alphanumeric character."}), 422

    # Create a Kubernetes API client
    v1 = client.CoreV1Api()

    # Define the pod spec
    pod = client.V1Pod(
        metadata=client.V1ObjectMeta(
            name=name,
            labels={"app": name},  # Generic app label based on name
            annotations={
                "expiration-time": expiration_time,
                "cluster-autoscaler.kubernetes.io/ttl": "3600"  # Set TTL for 1 hour
            }
        ),
        spec=client.V1PodSpec(
            containers=[
                client.V1Container(
                    name=name,
                    image=image,
                    ports=[client.V1ContainerPort(container_port=port) for port in container_ports],
                    env=[client.V1EnvVar(name=env['name'], value=env['value']) for env in env_vars if 'name' in env and 'value' in env]
                )
            ],
        )
    )

    service = client.V1Service(
        metadata=client.V1ObjectMeta(name=name),  # Use the same name as the pod
        spec=client.V1ServiceSpec(
            selector={"app": name},
            ports=[client.V1ServicePort(port=port, target_port=port) for port in container_ports],
            type='NodePort'
        )
    )

    # Create the pod in the default namespace
    try:
        v1.create_namespaced_pod(namespace="default", body=pod)
        v1.create_namespaced_service(namespace="default", body=service)
        return jsonify({"message": f"Pod {name} created successfully"}), 200
    except client.exceptions.ApiException as e:
        return jsonify({"error": str(e)}), 500


@app.route('/get_pods', methods=['GET'])
def get_pods():
    # Create a Kubernetes API client
    v1 = client.CoreV1Api()

    # List all pods in the default namespace
    try:
        # List all pods and services in the default namespace
        pods = v1.list_namespaced_pod(namespace="default")
        services = v1.list_namespaced_service(namespace="default")

        # Extract public IP of the master node
        master_node_ip = "13.200.238.161"

         # Ensure we have the master node's public IP
        if not master_node_ip:
            return jsonify({"error": "Master node public IP not found"}), 500

        # Map service names to NodePorts
        service_ports = {}
        for service in services.items:
            if service.spec.type == 'NodePort':
                node_ports = []
                for port in service.spec.ports:
                    node_ports.append({
                        'port': port.port,
                        'node_port': port.node_port
                    })
                service_ports[service.metadata.name] = node_ports

        pod_list = []
        for pod in pods.items:
            pod_name = pod.metadata.labels.get("app", "")
            node_name = pod.spec.node_name
            expiration_time = pod.metadata.annotations.get("expiration-time")

            # Check if a corresponding NodePort service exists for the pod
            if pod_name in service_ports:
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
            pod_list.append(pod_info)

        return jsonify({"pods": pod_list}), 200
    except client.exceptions.ApiException as e:
        return jsonify({"error": str(e)}), 500


@app.route('/get_ssh_creds', methods=['GET'])
def get_ssh_creds():
    pod_name = request.args.get('name')

    if not pod_name:
        return jsonify({"error": "Pod name is required"}), 400

    # Create a Kubernetes API client
    v1 = client.CoreV1Api()

    try:
        pod = v1.read_namespaced_pod(name=pod_name, namespace="default")
        node_name = pod.spec.node_name
        nodes = v1.list_node()

        # Extract public IPs of nodes
        node_ips = {}
        for node in nodes.items:
            for address in node.status.addresses:
                if address.type == "ExternalIP":
                    node_ips[node.metadata.name] = address.address
                elif address.type == "InternalIP" and node.metadata.name not in node_ips:
                    node_ips[node.metadata.name] = address.address

        if node_name in node_ips:
            node_ip = node_ips[node_name]
            ssh_command = f"ssh pod-user@{node_ip} -p 32222"
            return jsonify({"user_name": "pod-user", "node_ip": node_ip, "ssh_command": ssh_command}), 200
        else:
            return jsonify({"error": "Node IP not found"}), 404

    except client.exceptions.ApiException as e:
        return jsonify({"error": str(e)}), 500


@app.route('/get_nodes', methods=['GET'])
def get_nodes():
    # Create a Kubernetes API client
    v1 = client.CoreV1Api()

    # List all nodes
    try:
        nodes = v1.list_node()
        node_list = []

        for node in nodes.items:
            node_info = {
                "name": node.metadata.name,
                "status": node.status.conditions[-1].status,
                "addresses": {},
                "capacity": node.status.capacity,
                "allocatable": node.status.allocatable,
                "conditions": [],
                "labels": node.metadata.labels,
                "annotations": node.metadata.annotations,
                "taints": [],
                "node_info": node.status.node_info.to_dict()
            }

            for condition in node.status.conditions:
                node_info["conditions"].append({
                    "type": condition.type,
                    "status": condition.status,
                    "last_heartbeat_time": condition.last_heartbeat_time,
                    "last_transition_time": condition.last_transition_time,
                    "reason": condition.reason,
                    "message": condition.message
                })

            for address in node.status.addresses:
                if address.type == "InternalIP":
                    node_info["addresses"]["internal"] = address.address
                elif address.type == "ExternalIP":
                    node_info["addresses"]["external"] = address.address
                else:
                    # Capture any other types of addresses
                    node_info["addresses"][address.type] = address.address

            for taint in node.spec.taints or []:
                node_info["taints"].append({
                    "key": taint.key,
                    "value": taint.value,
                    "effect": taint.effect
                })

            node_list.append(node_info)

        return jsonify({"nodes": node_list}), 200
    except client.exceptions.ApiException as e:
        return jsonify({"error": str(e)}), 500


@app.route('/delete_pod/<pod_name>', methods=['DELETE'])
def delete_pod(pod_name):
    # Create a Kubernetes API client
    v1 = client.CoreV1Api()
    try:
        # Delete the pod
        v1.delete_namespaced_pod(name=pod_name, namespace="default",
                                 body=client.V1DeleteOptions(grace_period_seconds=0))

        # Delete associated service (if exists)
        try:
            v1.delete_namespaced_service(name=pod_name, namespace="default")
        except client.exceptions.ApiException as e:
            if e.status != 404:  # Ignore 404 errors indicating service not found
                return jsonify({"error": f"Failed to delete service {pod_name}: {str(e)}"}), 500

        # Delete associated persistent volume claim (PVC) (if exists)
        try:
            pvc_name = f"{pod_name}-pvc"  # Assuming PVC name convention
            v1.delete_namespaced_persistent_volume_claim(name=pvc_name, namespace="default")
        except client.exceptions.ApiException as e:
            if e.status != 404:  # Ignore 404 errors indicating PVC not found
                return jsonify({"error": f"Failed to delete PVC {pvc_name}: {str(e)}"}), 500

        # Add deletion for other associated resources like ConfigMaps, Secrets, etc. if needed

        return jsonify({"message": f"Pod {pod_name} and related resources deleted successfully"}), 200
    except client.exceptions.ApiException as e:
        return jsonify({"error": str(e)}), 500


@app.route('/delete_pods', methods=['DELETE'])
def delete_pods():
    # Create a Kubernetes API client
    v1 = client.CoreV1Api()
    try:
        # Retrieve list of pods using /get_pods endpoint
        get_pods_response = requests.get('http://localhost:8000/get_pods')
        if get_pods_response.status_code != 200:
            return jsonify(
                {"error": f"Failed to retrieve pods: {get_pods_response.text}"}), get_pods_response.status_code

        pod_list = get_pods_response.json()['pods']

        for pod_info in pod_list:
            pod_name = pod_info['name']
            # Call delete_pod endpoint for each pod
            delete_response = requests.delete(f'http://localhost:8000/delete_pod/{pod_name}')
            if delete_response.status_code != 200:
                return jsonify(
                    {"error": f"Failed to delete pod {pod_name}: {delete_response.text}"}), delete_response.status_code

        return jsonify({"message": "All pods and related resources deleted successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
