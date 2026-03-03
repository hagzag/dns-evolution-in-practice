#!/usr/bin/env bash
set -euo pipefail

for tool in docker k3d kubectl dig; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool"
    exit 1
  fi
done

if ! k3d cluster list | grep -q "dns-part1"; then
  echo "Creating cluster dns-part1..."
  k3d cluster create dns-part1
else
  echo "Cluster dns-part1 already exists"
fi

kubectl create configmap bind9-config \
  --from-file=named.conf=./zones/named.conf \
  --from-file=db.lab.dns=./zones/db.lab.dns.zone \
  --dry-run=client \
  -o yaml | kubectl apply -f -

if ls manifests/*.yaml >/dev/null 2>&1; then
  kubectl apply -f manifests/
  kubectl rollout status deployment/bind9 --timeout=120s
  kubectl wait --for=condition=Ready pod/debug --timeout=120s
  echo "Applied manifests from practice/part1/manifests"
else
  echo "No manifests found yet in practice/part1/manifests"
fi

cat <<'EOF'
Lab is ready. Try these commands:

kubectl exec -it debug -- cat /etc/hosts
kubectl exec -it debug -- cat /etc/nsswitch.conf
kubectl exec -it debug -- cat /etc/resolv.conf

kubectl exec -it debug -- dig @bind9 lab.dns SOA
kubectl exec -it debug -- dig @bind9 www.lab.dns A
kubectl exec -it debug -- dig @bind9 lab.dns MX
kubectl exec -it debug -- dig @bind9 lab.dns TXT
kubectl exec -it debug -- dig @bind9 lab.dns NS

kubectl exec -it debug -- dig +trace portfolio.hagzag.com

# Edit zones/db.lab.dns.zone, bump serial, then:
bash ./reload.sh
kubectl exec -it debug -- dig @bind9 api.lab.dns A +short
EOF
