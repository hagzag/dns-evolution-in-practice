#!/usr/bin/env python3
"""Educational use only: validates target constraints and exits safely."""

from __future__ import annotations

import argparse
import ipaddress
import sys


def is_private_or_lab(value: str) -> bool:
    if value.endswith(".lab.dns"):
        return True
    if value.endswith(".svc.cluster.local"):
        return True
    try:
        ip = ipaddress.ip_address(value)
    except ValueError:
        return False
    return ip.is_private


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True)
    parser.add_argument("--qname", default="bank.lab.dns")
    args = parser.parse_args()

    if not is_private_or_lab(args.target):
        print("Refusing to run: target must be private IP or *.lab.dns", file=sys.stderr)
        return 2

    if not args.qname.endswith(".lab.dns"):
        print("Refusing to run: qname must be in .lab.dns", file=sys.stderr)
        return 2

    print("Educational use only.")
    print(f"Validated target={args.target} qname={args.qname}")
    print("No packets sent. This script is intentionally non-transmitting.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
