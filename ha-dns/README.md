# HA DNS Setup

This directory contains the configuration for my highly available DNS infrastructure based on:

* **Technitium DNS Server**
* **Keepalived**
* **Docker Compose**

The setup, for now, runs on **2x Raspberry Pi 4B** devices and provides a redundant DNS service with automatic failover using a shared Virtual IP (VIP).

# Architecture Overview

| Host                 | Role          | IP Address   | Description  |
| -------------------- | ------------- | ------------ | ------------ |
| `<MASTER_HOST>`      | MASTER        | `<IP_MASTER>`| Primary DNS node holding the VIP during normal operation |
| `<BACKUP_HOST>`      | BACKUP        | `<IP_BACKUP>`| Secondary DNS node ready to take over automatically | 
| Virtual IP (VIP)     | Shared DNS IP | `<VIP>`      | Shared Virtual IP used by all clients

The VIP is managed using **Keepalived** and automatically moves between nodes depending on service health and node availability. Clients only interact with the Virtual IP, allowing transparent failover between both nodes.


# Components

## Technitium DNS Server

Technitium provides:

* Local DNS zones
* Recursive DNS resolution
* Ad-blocking and filtering
* Web management interface

Upstream DNS requests are forwarded to Quad9 using encrypted DNS-over-HTTPS.


## Keepalived

Keepalived is used to provide High Availability through:

* VRRP failover
* Health checking
* Automatic VIP migration
* MASTER/BACKUP election

The DNS health is monitored using:

```bash
nc -z 127.0.0.1 53
```

If the DNS service becomes unavailable, the node loses priority and failover occurs automatically.

# Usage

1. Configure the required placeholders inside:

* `keepalived_master.conf`
* `keepalived_backup.conf`

```text
<MASTER_HOST>
<BACKUP_HOST>
<IP_MASTER>
<IP_BACKUP>
<VIP>
<INTERFACE> # Interface name in the host to hold the VIP
<AUTH_PASSWORD>
<UNIQUE_ID> # Must be the same ID in both config files
```

2. Rename the desired configuration depending on the node role:

* MASTER node -> `keepalived_master.conf`
* BACKUP node -> `keepalived_backup.conf`

to:

```text
./keepalived/keepalived.conf
```

3. Create a `.env` file in both devices and configure the required environment variables:

```env
SERVER_NAME=server_name
ADMIN_PASSWORD=change_me
ALLOWED_NETWORKS=<IP>/<MASK>
```

4. Start the stack:

```bash
docker compose up -d
```
