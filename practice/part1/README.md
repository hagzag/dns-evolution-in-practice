# Part 1 - From /etc/hosts to BIND-9

**Companion lab for:** DNS Part 1 - From `/etc/hosts` to BIND-9  
**Cluster name:** `dns-part1`  
**Estimated time:** 10-15 minutes

## What you'll see

You will run an authoritative BIND-9 server in a local k3d cluster and query your own `lab.dns` zone with `dig`. The point is to make DNS tangible again: zone file on disk, authoritative answers on the wire, and a visible reload cycle after you change records.

## Prereqs

- Docker
- `k3d` (v5+)
- `kubectl`
- `dig` (from `bind`/`dnsutils`)

## Run it

From this directory:

```bash
bash ./run.sh
```

Or from repo root:

```bash
task part1:run
```

## Manual walkthrough

### 1) Inspect resolver inputs inside the debug pod

```bash
kubectl exec -it debug -- cat /etc/hosts
kubectl exec -it debug -- cat /etc/nsswitch.conf
kubectl exec -it debug -- cat /etc/resolv.conf
```

Expected:
- `/etc/hosts` includes loopback entries
- `hosts:` line in `nsswitch.conf` includes both files and dns
- `resolv.conf` points to cluster DNS

### 2) Query your authoritative BIND server

```bash
kubectl exec -it debug -- dig @bind9 lab.dns SOA
kubectl exec -it debug -- dig @bind9 www.lab.dns A
kubectl exec -it debug -- dig @bind9 lab.dns MX
kubectl exec -it debug -- dig @bind9 lab.dns TXT
kubectl exec -it debug -- dig @bind9 lab.dns NS
```

Expected highlights:
- SOA serial starts at `2026050301`
- `www.lab.dns` resolves to `10.10.10.20`
- MX points to `mail.lab.dns.`
- TXT includes `v=spf1 mx -all`
- NS includes `ns1.lab.dns.` and `ns2.lab.dns.`

### 3) Trace a public lookup root -> TLD -> authoritative

```bash
kubectl exec -it debug -- dig +trace portfolio.hagzag.com
```

Expected:
- output shows referrals from root servers to TLD and then authoritative

### 4) Edit zone, bump serial, reload, verify

Edit `zones/db.lab.dns.zone` and change one record (for example, `api`), then bump SOA serial.

Example serial bump:

```zone
2026050302 ; serial
```

Reload BIND from local files:

```bash
bash ./reload.sh
```

Verify changed answer:

```bash
kubectl exec -it debug -- dig @bind9 api.lab.dns A +short
```

Expected:
- answer reflects your edited zone file value

## What's happening

- `run.sh` creates a local cluster (`dns-part1`) and applies Kubernetes manifests.
- BIND configuration and zone content are loaded via a ConfigMap generated from `zones/named.conf` and `zones/db.lab.dns.zone`.
- `reload.sh` re-syncs the ConfigMap from your local files and restarts the BIND deployment so your edits are served.
- The debug pod uses default cluster DNS, so authoritative queries in this lab use `dig @bind9 ...` explicitly.

## Takeaway questions

1. What changes if you forget to bump the SOA serial before reloading?
2. Why do we still have `/etc/hosts` in modern systems?
3. Which record type in your current production zone is least understood by your team?

## Cleanup

```bash
bash ./cleanup.sh
```

or:

```bash
task part1:cleanup
```

## Going further

- Add a second MX record with different priority and compare output ordering.
- Add `AAAA` records for more subdomains and verify dual-stack responses.
- Intentionally break zone syntax, run `bash ./reload.sh`, and observe failure behavior.

## Next

- Continue to `practice/part2/` for Consul + CoreDNS service discovery.
