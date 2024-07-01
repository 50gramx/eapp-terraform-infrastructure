from flask import Flask, request, jsonify
from kubernetes import client, config
import os

app = Flask(__name__)

# Load the Kubernetes configuration
config.load_kube_config()  # This assumes you have a kubeconfig file set up

@app.route('/create_pod', methods=['POST'])
def create_pod():
    data = request.get_json()

    # Validate input
    if not data or 'name' not in data:
        return jsonify({"error": "Invalid input"}), 400

    name = data['name']
    image = "linuxserver/openssh-server"

    # Create a Kubernetes API client
    v1 = client.CoreV1Api()

    # Define the pod spec
    pod = client.V1Pod(
        metadata=client.V1ObjectMeta(name=name, labels={"app": "ssh"}),
        spec=client.V1PodSpec(containers=[
            client.V1Container(
                name=name,
                image=image,
                ports=[client.V1ContainerPort(container_port=22)],
                env=[{
                    "name": "USER_NAME",
                    "value": "pod-user"
                }, {
                    "name": "USER_PASSWORD",
                    "value": "123456789"
                }, {
                    "name": "PASSWORD_ACCESS",
                    "value": "true"
                }, {
                    "name": "PUID",
                    "value": "1000"
                }, {
                    "name": "PGID",
                    "value": "1000"
                }, {
                    "name": "TZ",
                    "value": "Etc/UTC"
                }]
            )
        ])
    )

    service = client.V1Service(
        metadata=client.V1ObjectMeta(name=name),
        spec=client.V1ServiceSpec(
            selector={"app": "ssh"},
            ports=[client.V1ServicePort(port=2222, target_port=2222, node_port=32222)],
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

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
