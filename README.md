# Linux Network Health Monitor

A simple, automated toolkit to check for and alert on common network hardware failures on Ubuntu/Debian-based systems.

## The Problem

On Linux, network hardware can sometimes fail "silently." A power surge or component failure can leave a network card in a state where the operating system's driver loads correctly, but the card's radio or physical port is non-functional.

This leads to a frustrating troubleshooting experience where the system reports no obvious errors, but the device simply cannot connect. This toolkit was developed to automate the diagnosis of these "silent failures."

## How It Works

This toolkit consists of three components that work together:

1.  **Health Check Script (`network-health-check.sh`)**: A core `bash` script that inspects all physical network interfaces. It runs a series of checks based on the interface type (wired or wireless) to detect common failure symptoms.
2.  **Systemd Service (`network-health.service`)**: A `systemd` unit that runs the health check script automatically every time the system boots up.
3.  **MOTD Alert (`30-network-health-motd`)**: A "Message of the Day" script that queries the system log for recent errors from the health check. If errors are found, it displays a prominent alert in the terminal as soon as a user logs in.

## Features

- **Automated Checks**: Runs automatically at boot, requiring no manual intervention.
- **Universal Interface Support**: Intelligently detects and checks all physical network interfaces, not just one.
- **Failure Detection**:
    - Alerts on any interface in a non-UP (`DOWN`) state.
    - **For Ethernet**: Checks for a `NO-CARRIER` status, which can indicate a bad cable, port, or dead card.
    - **For Wi-Fi**: Checks for the inability to perform a network scan, which is a key symptom of a failed radio.
- **Visible Alerting**: Provides immediate, high-visibility alerts in the terminal upon login, ensuring hardware problems don't go unnoticed.
- **Detailed Logging**: All checks and results are logged to the system's journal for detailed historical analysis.

## Installation

1.  Place the `install.sh` and `uninstall.sh` files into a directory on the target machine.
2.  Make the scripts executable:
    ```bash
    chmod +x install.sh uninstall.sh
    ```
3.  Run the installer with root privileges:
    ```bash
    sudo ./install.sh
    ```

The installer will copy all necessary files to their correct locations, set permissions, and enable the startup service.

## Usage

Once installed, the system is fully automated.

-   **Alerts**: If a hardware fault is detected at boot, a red `!! NETWORK HEALTH ALERT !!` will be displayed the next time you open a terminal or SSH into the machine.
-   **Logs**: To view the detailed logs from all health checks (both past and present), run the following command:
    ```bash
    journalctl -t network-health --no-pager
    ```

## Uninstallation

To completely remove the toolkit from your system, run the uninstaller with root privileges from the directory where you saved it:
```bash
sudo ./uninstall.sh


