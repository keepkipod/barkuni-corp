from flask import Flask, jsonify
from kubernetes import client, config

app = Flask(__name__)

def get_kube_system_pods():
    """
    Returns a list of pod names running in the 'kube-system' namespace.
    Tries in-cluster config first, then falls back to local kubeconfig.
    """
    try:
        config.load_incluster_config()
    except Exception:
        config.load_kube_config()
    v1 = client.CoreV1Api()
    pods = v1.list_namespaced_pod(namespace="kube-system")
    return [pod.metadata.name for pod in pods.items]

@app.route("/")
def welcome():
    return "Welcome to Barkuni Corp's Flask API!"

@app.route("/api/pods", methods=["GET"])
def api_pods():
    pods = get_kube_system_pods()
    return jsonify({"pods": pods})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
