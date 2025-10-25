Some AMD Ryzen-based systems **may experience random reboots** when running Proxmox as the hypervisor. This issue is related to how certain Ryzen CPUs handle power states and interrupts under virtualization workloads.

To prevent random reboots on Proxmox instances using AMD processors, update the GRUB configuration by replacing the existing line **GRUB_CMDLINE_LINUX_DEFAULT** in `/etc/default/grub` with the following:

```sh
GRUB_CMDLINE_LINUX_DEFAULT="quiet pci=assign-busses apicmaintimer idle=poll reboot=cold,hard"
```

Then, apply the changes and reboot:

```sh
update-grub
reboot
```

More details can be found in this discussion: [Proxmox Mystery Random Reboots](https://forum.proxmox.com/threads/proxmox-mystery-random-reboots.125001/)