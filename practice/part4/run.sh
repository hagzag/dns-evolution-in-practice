#!/usr/bin/env bash
set -euo pipefail

cat <<'EOF'
Educational use only.
This lab is for local, controlled environments you own.
Do not target external networks, domains, or systems.
EOF

read -r -p "Type 'y' to continue: " confirm
if [ "$confirm" != "y" ]; then
  echo "Aborted."
  exit 1
fi

for tool in docker k3d kubectl dig python3; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing required tool: $tool"
    exit 1
  fi
done

if ! command -v tshark >/dev/null 2>&1 && ! command -v wireshark >/dev/null 2>&1; then
  echo "Missing required tool: tshark (or wireshark)"
  exit 1
fi

if ! k3d cluster list | grep -q "dns-part4"; then
  echo "Creating cluster dns-part4..."
  k3d cluster create dns-part4
else
  echo "Cluster dns-part4 already exists"
fi

kubectl apply -f manifests/namespaces.yaml
kubectl apply -f legit-zone/
kubectl apply -f attacker/scripts-configmap.yaml

LEGIT_DNS_IP=$(kubectl -n legit-zone get svc legit-zone-dns -o jsonpath='{.spec.clusterIP}')
kubectl -n attacker create configmap attacker-dnsmasq-config \
  --from-literal=dnsmasq.conf="no-resolv
log-queries
log-facility=-
address=/bank.lab.dns/10.255.255.254
server=/lab.dns/${LEGIT_DNS_IP}
server=8.8.8.8" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f attacker/dnsmasq-deployment.yaml

kubectl -n verifying-resolver create configmap verifying-resolver-dnsmasq-config \
  --from-literal=dnsmasq.conf="no-resolv
log-queries
log-facility=-
server=/lab.dns/${LEGIT_DNS_IP}
server=1.1.1.1" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f verifying-resolver/unbound-deployment.yaml
kubectl apply -f victim/

kubectl rollout status -n legit-zone deployment/legit-zone-bind9 --timeout=180s
kubectl rollout status -n attacker deployment/attacker-dns --timeout=180s
kubectl rollout status -n verifying-resolver deployment/verifying-resolver --timeout=180s
kubectl rollout status -n victim deployment/victim --timeout=180s

cat <<'EOF'
Lab is ready. Try these commands:

# Step 1: baseline via verifying resolver (lab domain)
kubectl -n victim exec deploy/victim -- dig @verifying-resolver.verifying-resolver.svc.cluster.local bank.lab.dns A

# Step 1b: optional +dnssec query against a public signed domain
kubectl -n victim exec deploy/victim -- dig @verifying-resolver.verifying-resolver.svc.cluster.local cloudflare.com A +dnssec

# Step 2: compromised path via attacker resolver
kubectl -n victim exec deploy/victim -- dig @attacker-dns.attacker.svc.cluster.local bank.lab.dns A

# Step 3: defense path back to verifying resolver
kubectl -n victim exec deploy/victim -- dig @verifying-resolver.verifying-resolver.svc.cluster.local bank.lab.dns A

# Step 4: safe non-transmitting forge script demo
target_ip=$(kubectl -n verifying-resolver get svc verifying-resolver -o jsonpath='{.spec.clusterIP}')
kubectl -n attacker exec deploy/attacker-dns -c tools -- python3 /scripts/forge_response.py --target "$target_ip" --qname bank.lab.dns

# Step 5: inspect packet anatomy in-memory only
kubectl -n attacker exec deploy/attacker-dns -c tools -- python3 /scripts/inspect_forged_packet.py
EOF
