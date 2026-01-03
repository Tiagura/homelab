# SMARTD NVMe Temperature & Health Alerts

This document describes how to configure **smartd** on **Proxmox** to monitor NVMe SSDs and execute a script to send alerts when certain conditions are met.

## Overview

**What this setup does:**

- Monitors NVMe SSD health and temperature using `smartd`
- Triggers alerts when:
  - Temperature exceeds defined thresholds
  - SMART / NVMe errors occur
  - NVMe Critical Warnings are raised
  - Percentage Used increases
- Executes a custom script to handle notifications
- Logs locally for auditing/debugging
- 
## Environment

- OS: Proxmox VE 
- Devices: NVMe SSDs (can be adapted to HDDs with minor changes)
- Notification system: Any script-based alerting (example uses [Gotify](https://gotify.net/))

---

## 1. smartd Configuration (`/etc/smartd.conf`)

Use the template below as a guide and replace `/dev/nvmeX` with the actual device name the NVMe SSD Storage. Add a separate line for each NVMe device to monitor and update `/etc/smartd.conf` accordingly.

> **NOTE:** When editing the file `/etc/smartd.conf` don’t forget to comment out the `DEVICESCAN` line, as also noted in the default configuration file.

### Base NVMe Template

```conf
/dev/nvmeX -d nvme -a -o on -S on \
    -n standby,24,q \
    -I 190 -I 194 \
    -W 5,65,75 \
    -i 9 \
    -m root \
    -M exec /path/to/script
```


### Explanation of Arguments

The explanation of the command and arguments is as follows:

| Argument | Description |
|----------|-------------|
| `-d nvme` | Specifies device type as NVMe |
| `-a` | Monitor all SMART attributes |
| `-o on` | Enable automatic online data collection |
| `-S on` | Enable automatic attribute saving |
| `-n standby,24,q` | Skip disks in standby, wake after 24 skipped tests, quiet logging |
| `-I 190 -I 194` | Ignore attributes 190 & 194 (temperature-related) to reduce noise |
| `-W 5,65,75` | Temperature tracking: 5°C delta, warning ≥65°C, critical ≥75°C |
| `-i 9` | Ignore power-on hours attribute |
| `-m root` | Required for executing external script via `-M exec` |
| `-M exec /path/to/script` | Execute a custom script instead of sending email alerts |


## 2. Alert Script

The script specified in `-M exec /path/to/script` is run whenever smartd detects a condition that meets the defined thresholds. While this example uses **Gotify** for notifications, the script can be adapted to send alerts via email, Slack, Teams, or any other system. 

The script file can be created at any location, but make sure the `-M exec` directive in `/etc/smartd.conf` matches the path where it is placed.

```bash
#!/bin/bash

ALERT_MSG="$(cat)"
LOGFILE="/var/log/smartd_alert.log"
HOSTNAME="$(hostname -f 2>/dev/null || hostname)"
DATE="$(date -Is)"

GOTIFY_URL="http(s)://<IP_OR_DNS>/message"
GOTIFY_TOKEN="TOKEN"    # Gotify Web: Users -> Create Users -> Create

{
  echo "[$DATE] smartd alert received"
  echo "$ALERT_MSG"
  echo "----------------------------------------"
} >> "$LOGFILE"

DEV="$(echo "$ALERT_MSG" | grep -oE '/dev/nvme[0-9]+' | head -n1)"
[ -z "$DEV" ] && DEV="Unknown device"

TEMP="$(echo "$ALERT_MSG" | grep -oE 'Temperature [0-9]+' | grep -oE '[0-9]+' | head -n1)"
PRIORITY=0
SEVERITY="INFO"

if echo "$ALERT_MSG" | grep -qi 'critical'; then
  PRIORITY=10
  SEVERITY="CRITICAL"
elif echo "$ALERT_MSG" | grep -qi 'reached limit'; then
  PRIORITY=5
  SEVERITY="WARNING"
fi

if [ -n "$TEMP" ]; then
  TITLE="SMART $SEVERITY: $DEV @ ${TEMP}°C on $HOSTNAME"
else
  TITLE="SMART $SEVERITY: $DEV on $HOSTNAME"
fi

# Example Gotify call (adapt to your alerting system)
curl -s --fail \
  --data-urlencode "title=$TITLE" \
  --data-urlencode "message=$ALERT_MSG" \
  --data-urlencode "priority=$PRIORITY" \
  "$GOTIFY_URL?token=$GOTIFY_TOKEN" \
  >> "$LOGFILE" 2>&1

exit 0
```

After creating the script file, give it executable permissions and set up the log file:

```bash
chmod 755 /path/to/script
# If the LOGFILE variable is changed, amend accordingly.
mkdir -p /var/log
touch /var/log/smartd_alert.log
chmod 644 /var/log/smartd_alert.log
```

## 3. Testing the Setup

To verify that smartd correctly triggers the alert script, you can use its test mode:
  1. Enable test execution by temporarily adding `-M test` to the `-M exec` line in /etc/smartd.conf for each NVMe device. This tells smartd to execute the script immediately for each monitored device instead of waiting for a real threshold to be reached.
      ```conf
      /dev/nvmeX -d nvme -a -o on -S on \
          ...
          -m root \
          -M exec /path/to/script \
          -M test 
      ```
  2. Restart smartd to apply the configuration:
      ```bash
      systemctl restart smartmontools
      ```
  3. Check the logs to confirm that the script was executed and alerts were generated:
      ```bash
      tail -f /var/log/smartd_alert.log
      journalctl -u smartmontools -f
      ```
  4. After verification, remove the `-M test` option and restart smartd:
      ```bash
      systemctl restart smartmontools
      systemctl status smartmontools
      ```

## 4. Logs & Debugging

### smartd logs

```bash
journalctl -u smartmontools
journalctl -fu smartmontools
```

### Script log

```bash
tail -f /var/log/smartd_alert.log
```


## 5. What Triggers Alerts

| Condition | Alert |
|--------|------|
| Temp ≥ 65°C | Warning |
| Temp ≥ 75°C | Critical |
| Temp change ≥ 5°C | Info |
| NVMe Critical Warning | Critical |
| Media/Data errors | Critical |
| Percentage Used increase | Info |


## Final Notes

- smartd checks every ~30 minutes
- Thanks to the `-M exec /path/to/script` function for executing alerts and some tweaks to the smartd command template, this approach can be used to monitor other disk types and utilise different alert methods.

