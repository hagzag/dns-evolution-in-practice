#!/usr/bin/env bash
set -euo pipefail

echo "Applying failover DNS config (remove EU answers)..."
kubectl apply -f manifests/custom-coredns-failover.yaml
kubectl rollout restart deployment/custom-coredns
kubectl rollout status deployment/custom-coredns --timeout=120s

echo
echo "Immediate sample via cached resolver (old answers may still be cached):"
for _ in $(seq 1 10); do
  line=$(kubectl exec debug -- dig +short @cached-resolver web.lab.dns A 2>/dev/null | { read -r v || true; echo "$v"; } || true)
  echo "  ${line:-<no-answer>}"
done

echo
echo "Waiting for TTL window (65s)..."
sleep 65

echo "Post-TTL sample via cached resolver (should be US only):"
for _ in $(seq 1 10); do
  line=$(kubectl exec debug -- dig +short @cached-resolver web.lab.dns A 2>/dev/null | { read -r v || true; echo "$v"; } || true)
  echo "  ${line:-<no-answer>}"
done
