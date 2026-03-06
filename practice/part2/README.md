# Part 2 - Service Discovery with Consul and CoreDNS

**Companion lab for:** DNS Part 2 - DNS at Scale  
**Cluster name:** `dns-part2`  
**Estimated time:** 15-20 minutes

## What you'll see

This lab puts two discovery models next to each other: Consul catalog DNS (`*.service.consul`) and Kubernetes service discovery via CoreDNS. Then it reproduces the `ndots:5` behavior most clusters inherit by default and compares it to a pod with `ndots:1`.

## Prereqs

- Docker
- `k3d` (v5+)
- `kubectl`
- `helm`
- `dig`

## Run it

From this directory:

```bash
bash ./run.sh
```

Or from repo root:

```bash
task part2:run
```

## Manual walkthrough

### 1) Query Consul DNS for a registered service

```bash
kubectl exec -it debug -- dig @consul-dns.consul.svc.cluster.local echo.service.consul
kubectl exec -it debug -- dig @consul-dns.consul.svc.cluster.local echo.service.consul SRV
```

Expected:
- A response for `echo.service.consul`
- SRV output includes port `5678`

### 2) Query Kubernetes service discovery through CoreDNS

```bash
kubectl exec -it debug -- dig echo-headless.default.svc.cluster.local
kubectl exec -it debug -- dig _http._tcp.echo-headless.default.svc.cluster.local SRV
```

Expected:
- A/AAAA output resolves pod-backed records for the headless service
- SRV query returns one entry per healthy endpoint

### 3) Inspect CoreDNS Corefile

```bash
kubectl -n kube-system get configmap coredns -o yaml
```

Look for these plugins in the Corefile:
- `kubernetes`: serves in-cluster DNS names under `cluster.local`
- `forward`: forwards non-cluster queries upstream
- `cache`: caches responses to reduce upstream load and latency

### 4) Reproduce the default `ndots:5` behavior

```bash
kubectl exec -it debug -- cat /etc/resolv.conf
kubectl exec -it debug -- bash -lc 'time for i in $(seq 1 100); do dig +short google.com >/dev/null; done'
```

Expected:
- `options ndots:5` is present
- lookup loop completes, usually slower than the fixed pod

### 5) Compare with a pod that forces `ndots:1`

```bash
kubectl exec -it debug-fixed -- cat /etc/resolv.conf
kubectl exec -it debug-fixed -- bash -lc 'time for i in $(seq 1 100); do dig +short google.com >/dev/null; done'
```

Expected:
- `options ndots:1` is present
- loop often finishes faster than the default pod (depends on environment and cache state)

## What's happening

- `run.sh` creates `dns-part2`, installs Consul via pinned Helm chart version, and deploys demo workloads.
- It registers `echo` in Consul catalog so `echo.service.consul` resolves through Consul DNS on port `8600`.
- `echo-headless` demonstrates Kubernetes endpoint-style DNS and SRV records.
- `debug` uses cluster defaults, while `debug-fixed` overrides resolver options to `ndots:1`.

## Takeaway questions

1. Which discovery path is the source of truth in your production stack right now: kube API, Consul catalog, or both?
2. How much DNS search-domain overhead is acceptable in your latency budget?
3. If CoreDNS fails in-cluster, what is your blast radius?

## Cleanup

```bash
bash ./cleanup.sh
```

or:

```bash
task part2:cleanup
```

## Going further

- Increase lookup count from 100 to 1000 and compare timing variance.
- Add a second Consul service and compare DNS responses by service name.
- Evaluate NodeLocal DNSCache for large clusters with high external lookup volume.

## Next

- Continue to `practice/part3/` for weighted DNS and TTL-bound failover behavior.
