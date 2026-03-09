#!/usr/bin/env bash
set -euo pipefail

declare -A counts

for i in $(seq 1 200); do
  ip=$(kubectl exec debug -- dig +short @custom-coredns web.lab.dns A 2>/dev/null | { read -r line || true; echo "$line"; } || true)
  if [ -n "$ip" ]; then
    counts["$ip"]=$(( ${counts["$ip"]:-0} + 1 ))
  fi
done

if [ "${#counts[@]}" -eq 0 ]; then
  echo "No DNS answers received from custom-coredns."
  echo "Run 'task part3:run' and check custom-coredns pod logs."
  exit 1
fi

echo "Weighted sample results (200 queries):"
for ip in "${!counts[@]}"; do
  echo "  $ip: ${counts[$ip]}"
done
