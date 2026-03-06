#!/usr/bin/env bash
set -euo pipefail

for tool in docker k3d kubectl helm dig; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool"
    exit 1
  fi
done

if ! k3d cluster list | grep -q "dns-part2"; then
  echo "Creating cluster dns-part2..."
  k3d cluster create dns-part2
else
  echo "Cluster dns-part2 already exists"
fi

helm repo add hashicorp https://helm.releases.hashicorp.com >/dev/null 2>&1 || true
helm repo update >/dev/null

helm upgrade --install consul hashicorp/consul \
  --namespace consul \
  --create-namespace \
  --version 1.5.3 \
  --values manifests/consul-values.yaml

kubectl -n consul rollout status statefulset/consul-server --timeout=300s

kubectl apply -f manifests/echo-services.yaml
kubectl apply -f manifests/debug-pod.yaml
kubectl apply -f manifests/debug-fixed.yaml

kubectl rollout status deployment/echo-clusterip --timeout=120s
kubectl rollout status deployment/echo-headless --timeout=120s
kubectl wait --for=condition=Ready pod/debug --timeout=120s
kubectl wait --for=condition=Ready pod/debug-fixed --timeout=120s

CONSUL_SERVER_POD=$(kubectl -n consul get pod -l app=consul,component=server -o jsonpath='{.items[0].metadata.name}')
ECHO_IP=$(kubectl get svc echo-clusterip -o jsonpath='{.spec.clusterIP}')

kubectl -n consul exec "$CONSUL_SERVER_POD" -- sh -lc "cat >/tmp/echo.json <<'EOF'
{
  \"service\": {
    \"id\": \"echo-service-consul\",
    \"name\": \"echo\",
    \"address\": \"${ECHO_IP}\",
    \"port\": 5678
  }
}
EOF
consul services deregister -id echo-service-consul >/dev/null 2>&1 || true
consul services register /tmp/echo.json"

cat <<'EOF'
Lab is ready. Try these commands:

kubectl exec -it debug -- dig @consul-dns.consul.svc.cluster.local echo.service.consul
kubectl exec -it debug -- dig @consul-dns.consul.svc.cluster.local echo.service.consul SRV

kubectl exec -it debug -- dig echo-headless.default.svc.cluster.local
kubectl exec -it debug -- dig _http._tcp.echo-headless.default.svc.cluster.local SRV

kubectl -n kube-system get configmap coredns -o yaml

kubectl exec -it debug -- cat /etc/resolv.conf
kubectl exec -it debug -- bash -lc 'time for i in $(seq 1 100); do dig +short google.com >/dev/null; done'

kubectl exec -it debug-fixed -- cat /etc/resolv.conf
kubectl exec -it debug-fixed -- bash -lc 'time for i in $(seq 1 100); do dig +short google.com >/dev/null; done'
EOF
