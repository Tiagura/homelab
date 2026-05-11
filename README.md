# Homelab Documentation

This repository serves as the main reference for my homelab setup and infrastructure.

## Hardware Overview

My homelab currently consists of the following devices:

* **GL.iNet Flint 2 (GL-MT6000)**: Running **OpenWRT** as the main firewall, router, and wireless access point for the network.

* **GMKTEC M5 PLUS**: Running **Proxmox VE** as the primary virtualization host.

* **2x Raspberry Pi 4B**: Running a highly available DNS Server.

# Logical Network Architecture

The homelab is organized into multiple logical services and environments running on top of the Proxmox infrastructure.

## Kubernetes Cluster

A Kubernetes cluster runs inside Proxmox virtual machines and serves as the primary orchestration platform for containerized workloads and self-hosted applications.

The infrastructure provisioning and cluster bootstrap process are managed through my IaC project: [proxmox-k8s-IaC](https://github.com/Tiagura/proxmox-k8s-IaC)

The Kubernetes workloads and cluster configuration are managed using GitOps with ArgoCD: [k8s-gitops](https://github.com/Tiagura/k8s-gitops)

## Docker VMs

Dedicated Docker virtual machines are used for standalone services, temporary workloads, and testing environments that do not require Kubernetes orchestration.
* **Nginx Proxy Manager (NPM)** for reverse proxy management and HTTPS termination
* Miscellaneous self-hosted services and test applications

## Remote Access

A dedicated **Tailscale Exit Node** runs inside an LXC container, providing secure remote access to the homelab network and optional outbound traffic routing through the home connection. The setup and configuration are documented in: [tailscale-exit-node](./tailscale-exit-node/)

## DNS Infrastructure

The DNS layer is built using:

* **Technitium DNS Server**
* **Keepalived** for High Availability

Both RPIs operate as a DNS cluster, while Keepalived manages a shared virtual IP (VIP) to ensure seamless failover and uninterrupted DNS availability across the network.

Features include:
* Local DNS resolution
* Ad-blocking and filtering
* Redundancy and failover
* Internal domain management

The DNS HA setup and configuration are documented in: [ha-dns](./ha-dns/)

## Network Edge

The network edge is managed by the **GL.iNet Flint 2** running **OpenWRT**.

Responsibilities include:

* Routing
* Firewalling
* VLAN management
* Wireless networking
* DHCP

---

This documentation will continue evolving alongside the homelab infrastructure. 🚀