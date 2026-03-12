# Part 4 - When DNS Lies (Spoofing vs Resolver Defenses)

## Mandatory Disclaimer

**Educational use only.** This lab exists to help practitioners understand and defend against DNS abuse in a self-contained environment.

- Run this only on local infrastructure you own.
- Do not target external networks, domains, or systems.
- Packet-inspection scripts in this repo are intentionally non-transmitting or constrained.
- If a step can be abused as a public attack path, it is out of scope for this lab.

## What you'll see

You will compare answers for the same name (`bank.lab.dns`) from two resolver paths:

- a controlled resolver path (`victim -> verifying-resolver -> legit-zone`)
- a malicious resolver path (`victim -> attacker-dns`)

Then you will inspect forged packet anatomy in memory to understand why unsigned DNS data can be faked.

## Prereqs

- Docker
- `k3d` (v5+)
- `kubectl`
- `dig`
- `python3`
- `tshark` or Wireshark

## Architecture

```text
victim
  | \
  |  \---> attacker-dns (forged answer for bank.lab.dns)
  |
  \-----> verifying-resolver (unbound) ---> legit-zone (authoritative bind9)
```

## Run it

From this directory:

```bash
bash ./run.sh
```

Or from repo root:

```bash
task part4:run
```

## Walkthrough

### Step 1 - Baseline with verifying resolver

```bash
kubectl -n victim exec deploy/victim -- dig @verifying-resolver.verifying-resolver.svc.cluster.local bank.lab.dns A
```

Expected:
- answer contains `10.20.20.20`

Optional DNSSEC-flag visibility check on a public signed zone:

```bash
kubectl -n victim exec deploy/victim -- dig @verifying-resolver.verifying-resolver.svc.cluster.local cloudflare.com A +dnssec
```

Expected:
- response includes DNSSEC records in the additional sections (environment-dependent)

### Step 2 - Compromised resolver path

```bash
kubectl -n victim exec deploy/victim -- dig @attacker-dns.attacker.svc.cluster.local bank.lab.dns A
```

Expected:
- forged answer `10.255.255.254`

### Step 3 - Defense path back to verifying resolver

```bash
kubectl -n victim exec deploy/victim -- dig @verifying-resolver.verifying-resolver.svc.cluster.local bank.lab.dns A
```

Expected:
- real answer `10.20.20.20`

### Step 4 - Safe forge script demonstration

```bash
target_ip=$(kubectl -n verifying-resolver get svc verifying-resolver -o jsonpath='{.spec.clusterIP}')
kubectl -n attacker exec deploy/attacker-dns -c tools -- \
  python3 /scripts/forge_response.py --target "$target_ip" --qname bank.lab.dns
```

Expected:
- script validates target constraints and exits without sending packets

### Step 5 - Inspect forged packet anatomy (in memory only)

```bash
kubectl -n attacker exec deploy/attacker-dns -c tools -- python3 /scripts/inspect_forged_packet.py
```

Expected output includes:
- transaction ID
- question name (`bank.lab.dns`)
- forged answer IP (`10.255.255.254`)
- explicit note that `RRSIG` is absent

## What this lab does not do

- no cache-poisoning race logic
- no loops for repeated spoof attempts
- no targeting of external resolvers or authoritative servers
- no weaponized packet-injection workflow

## Cleanup

```bash
bash ./cleanup.sh
```

or:

```bash
task part4:cleanup
```

## Going further

- Add DNSSEC signing for `lab.dns` and configure explicit trust anchor validation in Unbound.
- Query signed records (for example `CAA`) through the verifying resolver and inspect `+dnssec` responses.
- Add observability around resolver logs to correlate cache state with response changes.
