# DNS Evolution in Practice - Companion Labs

Hands-on k3d labs for the blog series **"DNS - The Internet's Quiet Backbone"** by [Haggai Philip Zagury (HagZag)](https://portfolio.hagzag.com).
![](https://i.ibb.co/C3F0RVqY/DNS-intro-p0-i1.png)
Each post in the series ships a self-contained lab under `practice/partN/`, designed to run locally with no cloud account.

> ℹ️ **Read full series or intro at** [here](http://portfolio.hagzag.com/blog/reading-lists/dns-evolution-in-practice/2026-03-03-dns-series-introduction)

## Layout

```text
practice/
|- part1/   From /etc/hosts to BIND-9
|- part2/   DNS at Scale: Service Discovery (Consul + CoreDNS)
|- part3/   DNS as a Load Balancer (weighted + TTL failover)
`- part4/   When DNS Lies: Spoofing vs DNSSEC defense
```

Each lab folder contains:

- `README.md` walkthrough
- Kubernetes manifests
- `run.sh` and `cleanup.sh`
- `Taskfile.yaml` for per-part commands

## Prereqs

- Docker
- `k3d` (v5+)
- `kubectl` (v1.28+ recommended)
- `dig` (`bind`/`dnsutils`)
- `helm` (part 2)
- `python3` (part 4)
- `tshark` or Wireshark (part 4)

## Quickstart

```bash
task list
task check-tools
task part1:run
task part1:test
task part1:cleanup
```

Run all labs:

```bash
task all:run
task test-all
```

## Posts

![](https://i.ibb.co/ymj6k4pS/DNS-intro-p0-i2.png)

1. [Series introduction](posts/2026-05-04-dns-series-introduction.md)
2. [Part 1 - From /etc/hosts to BIND-9](posts/2024-01-02-dns-part-1-from-hosts-file-to-bind-9.md) - lab: `practice/part1/`
3. [Part 2 - Service Discovery with Consul and CoreDNS](posts/2026-05-03-dns-part-2-service-discovery-consul-coredns.md) - lab: `practice/part2/`
4. [Part 3 - DNS as a Load Balancer](posts/2026-05-03-dns-part-3-dns-as-a-load-balancer.md) - lab: `practice/part3/`
5. [Part 4 - When DNS Lies](posts/2026-05-03-dns-part-4-when-dns-lies.md) - lab: `practice/part4/`

## Safety Note (Part 4)

Part 4 includes a mandatory educational-use-only disclaimer. The lab is intentionally constrained to local, owned infrastructure and must never be used against external systems.

---

See you in the next series...