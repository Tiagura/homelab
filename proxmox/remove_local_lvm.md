# Remove `local-lvm` and Expand `local` Storage  

> **WARNING:** Only perform this on a **fresh Proxmox install**.  
> Doing this on an existing system with running or configured VMs **may result in data loss**.

## Overview

By default, Proxmox creates two storage volumes:
- **`local`** — used for ISO images, backups, and container templates.  
- **`local-lvm`** — used to store VM and container disks.  

If you prefer to manage all storage under a single directory (e.g., `/var/lib/vz`), you can safely remove the `local-lvm` volume and allocate its space to the `local` volume.

This approach is especially useful if you want to separete your boot drive from the rest. It allows you to use your boot disk entirely for the Proxmox installation and optionally store light files that don’t require many write cycles (helping extend your NVMe’s lifespan). You can then add a secondary drive to host your VM disks, backups, and other high-write data.

## Steps

### 1. Remove `local-lvm`
1. In the **Proxmox Web UI**:
   - Click **Datacenter → Storage**.
   - Select **`local-lvm`**.
   - Click **Remove**.

   *(This only removes the reference; no data will be deleted yet.)*

### 2. Reclaim Space from `local-lvm`
1. Open a **shell** on your Proxmox node.
2. Run the following commands one by one:

   ```sh
   lvremove /dev/pve/data
   lvresize -l +100%FREE /dev/pve/root
   resize2fs /dev/mapper/pve-root
   ```
