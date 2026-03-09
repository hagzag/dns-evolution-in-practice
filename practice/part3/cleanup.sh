#!/usr/bin/env bash
set -euo pipefail

if k3d cluster list | grep -q "dns-part3"; then
  k3d cluster delete dns-part3
  echo "Deleted cluster dns-part3"
else
  echo "Cluster dns-part3 does not exist; nothing to clean"
fi
