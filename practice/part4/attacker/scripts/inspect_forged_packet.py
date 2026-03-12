#!/usr/bin/env python3
"""Educational use only: inspect a forged DNS response in memory."""

from __future__ import annotations

import struct


def build_packet() -> bytes:
    txid = 0xBEEF
    flags = 0x8180
    qdcount = 1
    ancount = 1
    nscount = 0
    arcount = 0

    header = struct.pack("!HHHHHH", txid, flags, qdcount, ancount, nscount, arcount)

    qname = b"\x04bank\x03lab\x03dns\x00"
    question = qname + struct.pack("!HH", 1, 1)

    answer_name_ptr = struct.pack("!H", 0xC00C)
    answer_meta = struct.pack("!HHIH", 1, 1, 60, 4)
    answer_rdata = bytes([10, 255, 255, 254])

    return header + question + answer_name_ptr + answer_meta + answer_rdata


def main() -> None:
    packet = build_packet()
    txid, flags, qd, an, ns, ar = struct.unpack("!HHHHHH", packet[:12])

    print("Educational use only.")
    print("Forged DNS response anatomy (in memory only):")
    print(f"  transaction_id: 0x{txid:04x}")
    print(f"  flags: 0x{flags:04x}")
    print(f"  question_count: {qd}")
    print(f"  answer_count: {an}")
    print(f"  authority_count: {ns}")
    print(f"  additional_count: {ar}")
    print("  question_name: bank.lab.dns")
    print("  answer_type: A")
    print("  answer_ip: 10.255.255.254")
    print("  rrsig_present: no")


if __name__ == "__main__":
    main()
