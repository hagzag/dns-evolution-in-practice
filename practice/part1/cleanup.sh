#!/usr/bin/env bash
set -euo pipefail

if k3d cluster list | grep -q "dns-part1"; then
  k3d cluster delete dns-part1
  echo "Deleted cluster dns-part1"
else
  echo "Cluster dns-part1 does not exist; nothing to clean"
fi
