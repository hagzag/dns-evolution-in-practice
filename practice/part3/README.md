# Part 3 - DNS as a Load Balancer

**Companion lab for:** DNS Part 3 - DNS as a Load Balancer  
**Cluster name:** `dns-part3`  
**Estimated time:** 15-20 minutes

## What you'll see

This lab shows why DNS-based failover is bounded by TTL and cache behavior. You will query a weighted DNS answer set (`web.lab.dns`), simulate backend failure, then watch cached answers persist before convergence.

## Prereqs

- Docker
- `k3d` (v5+)
- `kubectl`
- `dig`

## Run it

From this directory:

```bash
bash ./run.sh
```

Or from repo root:

```bash
task part3:run
```

## Manual walkthrough

### 1) Sample weighted DNS responses

```bash
task sample
```

Expected:
- you should see two IPs with a visibly non-50/50 distribution over 200 queries

### 2) Simulate regional failure

```bash
kubectl scale deployment web-eu --replicas=0
kubectl rollout status deployment/web-eu --timeout=120s
```

### 3) Apply failover DNS config and observe cache behavior

```bash
task failover
```

Expected:
- immediate samples may still include the old (EU) answer from cache
- post-TTL samples should converge to US-only answers

### 4) Compare direct authoritative vs cached resolver answers

```bash
kubectl exec -it debug -- dig @custom-coredns web.lab.dns A
kubectl exec -it debug -- dig @cached-resolver web.lab.dns A
```

Expected:
- direct `custom-coredns` reflects latest zone quickly
- `cached-resolver` may lag until TTL expiry

## The TTL truth

DNS failover speed is not the same thing as application failover speed.

- If your cached resolver has a 60s TTL answer, changing authoritative records does not instantly update every client.
- This lab demonstrates that lag explicitly: a failover config is live, but cached answers can remain visible until their TTL window closes.
- That is why DNS is useful for traffic steering and coarse failover, but risky for strict sub-minute RTO promises.

## What's happening

- `run.sh` creates a 2-agent k3d cluster and labels nodes as `region=eu` and `region=us`.
- `web-eu` and `web-us` workloads are scheduled to separate labeled nodes.
- `custom-coredns` serves `lab.dns` with a weighted A-record set for `web.lab.dns`.
- `cached-resolver` (dnsmasq) sits in front to make TTL behavior visible.
- `failover.sh` swaps CoreDNS zone content to US-only and shows immediate vs post-TTL query differences.

## Cleanup

```bash
bash ./cleanup.sh
```

or:

```bash
task part3:cleanup
```

## Going further

- Change zone TTL from 60 to 5 and compare failover lag.
- Change weighted ratio in `custom-coredns-weighted.yaml` and rerun `task sample`.
- Replace manual failover with a controller or health-check based config updater.

## Next

- Continue to `practice/part4/` for spoofing and DNSSEC validation defense.
