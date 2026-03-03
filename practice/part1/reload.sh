#!/usr/bin/env bash
set -euo pipefail

kubectl create configmap bind9-config \
  --from-file=named.conf=./zones/named.conf \
  --from-file=db.lab.dns=./zones/db.lab.dns.zone \
  --dry-run=client \
  -o yaml | kubectl apply -f -

kubectl rollout restart deployment/bind9
kubectl rollout status deployment/bind9 --timeout=120s

echo "ConfigMap refreshed and bind9 restarted."
