#!/usr/bin/env bash
set -euo pipefail

for tool in docker k3d kubectl dig; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool"
    exit 1
  fi
done

if ! k3d cluster list | grep -q "dns-part3"; then
  echo "Creating cluster dns-part3..."
  k3d cluster create dns-part3 --agents 2
else
  echo "Cluster dns-part3 already exists"
fi

kubectl label node k3d-dns-part3-agent-0 region=eu --overwrite
kubectl label node k3d-dns-part3-agent-1 region=us --overwrite

kubectl apply -f manifests/web-services.yaml
kubectl apply -f manifests/custom-coredns-weighted.yaml
kubectl apply -f manifests/debug-pod.yaml

kubectl rollout restart deployment/custom-coredns >/dev/null 2>&1 || true

kubectl rollout status deployment/web-eu --timeout=120s
kubectl rollout status deployment/web-us --timeout=120s
kubectl rollout status deployment/custom-coredns --timeout=120s

COREDNS_IP=$(kubectl get svc custom-coredns -o jsonpath='{.spec.clusterIP}')
kubectl create configmap cached-resolver-config \
  --from-literal=dnsmasq.conf="no-resolv
cache-size=1000
neg-ttl=5
server=/lab.dns/${COREDNS_IP}
server=8.8.8.8" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f manifests/cached-resolver.yaml
kubectl rollout restart deployment/cached-resolver >/dev/null 2>&1 || true
kubectl rollout status deployment/cached-resolver --timeout=120s
kubectl wait --for=condition=Ready pod/debug --timeout=120s

cat <<'EOF'
Lab is ready. Try these commands:

task sample

kubectl scale deployment web-eu --replicas=0
kubectl rollout status deployment/web-eu --timeout=120s
task failover

kubectl exec -it debug -- dig @custom-coredns web.lab.dns A
kubectl exec -it debug -- dig @cached-resolver web.lab.dns A
EOF
