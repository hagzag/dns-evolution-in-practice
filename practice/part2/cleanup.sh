#!/usr/bin/env bash
set -euo pipefail

if k3d cluster list | grep -q "dns-part2"; then
  k3d cluster delete dns-part2
  echo "Deleted cluster dns-part2"
else
  echo "Cluster dns-part2 does not exist; nothing to clean"
fi
