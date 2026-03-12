#!/usr/bin/env bash
set -euo pipefail

if k3d cluster list | grep -q "dns-part4"; then
  k3d cluster delete dns-part4
  echo "Deleted cluster dns-part4"
else
  echo "Cluster dns-part4 does not exist; nothing to clean"
fi
