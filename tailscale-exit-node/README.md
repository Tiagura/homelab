# Tailscale Docker Exit Node

This repository provides the configuration files needed to set up a Tailscale Docker container as an exit node, allowing secure access to your home network through Tailscale.

This setup is desinged to work on Proxmox using an unprivileged LXC container with Docker installed. However this setup will probably work with any docker host.
---

## Setup Steps

### 1. Prerequisites
1. **Access to the /dev/tun device** for LXC only:
  Based on [official documentation](https://tailscale.com/kb/1130/lxc-unprivileged), in the Proxmox main shell do:
  1. Stop the container:
     ***bash
     pct stop <container_id>
     ***
  2. Edit the LXC configuration file:
     ***bash
     nano /etc/pve/lxc/<container_id>.conf
     ***
  3. Add the following lines:
     ***ini
     lxc.cgroup2.devices.allow: c 10:200 rwm
     lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
     ***
  4. Start the container:
     ***bash
     pct start <container_id>
     ***
     
2. **Install Git**:
  In the LXC shell do:
   ***bash
   sudo apt install git
   git --version
   ***
   
3. **Install Docker and Docker Compose**:
   Refer to the [official documentation](https://docs.docker.com/engine/install/debian/).

4. **Generate a Tailscale Auth Key**:
   - Log in to the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).
   - Generate an Auth Key for the container. You can choose:
     - **Single-use key** (recommended for added security): Expires after one use.
     - **Reusable key**: Convenient for repeated use but less secure.
   - Copy the generated key, as it will be required for authentication.
   

> **Note**: If on proxmox and whish to use an LXC, consider using [Proxmox VE Helper-Scripts](https://community-scripts.github.io/ProxmoxVE/scripts), more specifically this [one] (https://community-scripts.github.io/ProxmoxVE/scripts?id=docker), to create the LXC container and also skip step 3. Be carefull to not create a privileged LXC.

---

### 2. Configure the LXC and adapt files
1. Get this folder to your docker host:
   ***bash
   git clone <repository-url>
   mv homelab/tailscale-exit-node/ tailscale-exit-node/
   cd tailscale-exit-node/
   ***

2. Make the provided `enable_ip_forwarding.sh` script executable and execute it to configure IP forwarding:
   ***bash
   chmod +x enable_ip_forwarding.sh
   sudo bash enable_ip_forwarding.sh
   ***
   
> **Note**: Don't forget to also enable IP forwarding if in proxmox
   
3. Set the Docker Environment Variables:
   Create the `.env` file with the following required variables:
   - `TS_AUTHKEY`: The Tailscale Auth Key you generated earlier.
   - `TS_HOSTNAME`: The hostname to be assigned to this node in the Tailscale network.
   - `TS_ROUTES`: The subnet routes you want this node to advertise.
   - `TS_DEST_IP`: Proxy all incoming Tailscale traffic to the specified destination IP. Only this param if you have a proxy in your local network. 

   Example `.env` file:
   ***ini
   TS_AUTHKEY=your_tailscale_auth_key
   TS_HOSTNAME=exit-node
   TS_ROUTES=192.168.1.0/24
   TS_DEST_IP=<proxy private ip ex: 192.168.1.111>
   ***

   Ensure this file is in the same directory as the `docker-compose.yml` file.

4. Start the Tailscale Docker container:
   ***bash
   docker compose up -d
   ***

5. Check the logs of the Tailscale container to verify it is running correctly:
   ***bash
   docker logs tailscale-exit
   ***

6. If any errors are encountered, refer to the **Troubleshooting** section below.

---

### 3. Work in the Tailscale Admin Console
1. Log in to the [Tailscale Admin Console](https://login.tailscale.com/admin/machines).
2. Find the newly added machine corresponding to your Docker container.
3. Configure the machine settings:
   - Go to `... > Edit route settings`.
   - Tick the subnet routes.
   - Tick the option to use this machine as an exit node.
4. Save the changes.

---

## Troubleshooting

### **Tag Invalid or Not Permitted**
- **Error Message**:  
  `Requested tags [tag:container] are invalid or not permitted.`

- **Solution**:
  1. Log in to the [Tailscale Admin Console](https://login.tailscale.com/admin/acls/file).
  2. Navigate to the **Access Controls** section and locate the `tagOwners` ACL.
  3. Ensure the tag `tag:container` is defined and assigned to an owner. For example:
     ***json
     "tagOwners": {
         "tag:container": ["autogroup:admin"]
     }
     ***
  4. Save and apply the changes.

---

## Custom DNS Setup

If you want to use a custom DNS server (e.g., Pi-Hole) with Tailscale, there are two ways to configure it:
- **Split DNS**: Tailscale only uses your custom DNS server for specific sub-routes or domains (e.g., `myhome.local`).
- **Full DNS**: Tailscale sends all DNS queries through your custom DNS server.

### Split DNS Configuration
In this setup, Tailscale will use your custom DNS server (e.g., Pi-Hole) **only** for resolving queries related to your advertised subnets or specific local domains.

1. Navigate to the [DNS settings](https://login.tailscale.com/admin/dns).
2. In the **Nameserver** section:
   - Add your local domain (e.g., `myhome.local`).
   - Specify the IP address of your DNS server as the DNS server for that domain.
   - Tick the **Split DNS** option.
3. Save the configuration.

This ensures:
- Tailscale uses Pi-Hole for queries related to your home network domain (e.g., myhome.local).
- All other queries are resolved through the default DNS servers.

> **Note**: In this setup, only Split DNS is used.

---

## Additional Notes

- Refer to Tailscale's official documentation for more details:
  - [Using Docker with Tailscale](https://tailscale.com/kb/1282/docker)
  - [Proxmox Troubleshooting](https://tailscale.com/kb/1133/proxmox#troubleshooting)
  - [Exit Nodes in Tailscale](https://tailscale.com/kb/1103/exit-nodes)
  - [DNS Settings](https://tailscale.com/kb/1054/dns)
