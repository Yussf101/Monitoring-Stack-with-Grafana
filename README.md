# 📊 Grafana Monitoring Stack with Prometheus and Node Exporter (Docker-Based)

This repository contains a complete, production-ready **monitoring stack** for tracking multiple Linux systems' metrics(CPU, RAM, Storage...) with two pre-configured Grafana dashboards to suit different levels of system visibility using:

- [Grafana](https://grafana.com/): for dashboards and visualization.
- [Prometheus](https://prometheus.io/): for scraping and storing metrics.
- [Node Exporter](https://prometheus.io/docs/guides/node-exporter/): for exposing system metrics.

Everything runs in **Docker containers** via `docker-compose`.

## 📆 Project Structure

```
monitoring-project/
├── docker-compose.yml
├── generate-prometheus-config.sh
├── prometheus/
│   ├── prometheus.template.yml
│   └── prometheus.yml (available after generation)
├── grafana/
│   ├── grafana.ini
│   └── provisioning/
│       ├── dashboards/
│       │   └── node-main-dashboard.json
│       │   └── node-advanced-dashboard.json
│       │   └── node-minimal-dashboard.json
│       ├── datasources/
│       │   └── prometheus-datasource.yml
│       └── variables/
│           └── variables.yml
├── vm_list.txt
├── README.md
```
---

## 📁 Contents Overview

| File/Folder                                                    | Description                                                           |
| ------------------------------------------------------------   | --------------------------------------------------------------------- |
| `docker-compose.yml`                                           | Defines and starts Grafana and Prometheus services using Docker       |
| `generate-prometheus-config.sh`                                | Script to generate `prometheus.yml` dynamically from `vm_list.txt`    |
| `prometheus/`                                                  | Contains Prometheus configuration files                               |
| `prometheus/prometheus.template.yml`                           | Template with placeholder `${VM_LIST}` used to generate actual config |
| `prometheus/prometheus.yml`                                    | Config file with real targets for Prometheus (available after being generated)|
| `grafana/`                                                     | Contains Grafana configuration and provisioning folders                     |
| `grafana/grafana.ini`                                          | Main Grafana configuration (port, login, etc.)                        |
| `grafana/provisioning/dashboards/node-main-dashboard.json`     | Main Dashboard with pre-defined system metrics panels                 |
| `grafana/provisioning/dashboards/node-advanced-dashboard.json` | Same as Main Dashboard but with detailed kernel/system-level metrics  |
| `grafana/provisioning/dashboards/node-minimal-dashboard.json`  | Basic minimal dashboard to customize as you want                                              |
| `grafana/provisioning/datasources/prometheus-datasource.yml`   | Prometheus data source auto-provisioning                              |
| `grafana/provisioning/variables/variables.yml`                 | Allows defining custom variables in dashboards automatically          |
| `vm_list.txt`                                                  | List of IP addresses or hostnames of the VMs to monitor               |
| `README.md`                                                    | Full documentation of the project                                     |
 
---


---

## 🛠️ Prerequisites

- A Linux machine to run the monitoring stack (e.g., Ubuntu Server).
- Docker & Docker Compose installed.


## 🚀 Running the Monitoring Stack on the Monitoring Server

### Step 1: Clone the Repository

### Step 2: Add VM IPs to `vm_list.txt`

Edit the file:

```bash
nano vm_list.txt
```

Add one IP per line: (for example for 2 VMs)

```
192.159.29.129
192.159.29.130
```

### Step 3: Generate Prometheus Configuration

```bash
chmod +x generate-prometheus-config.sh
./generate-prometheus-config.sh
```

### Step 4: Start the Monitoring Stack

```bash
docker-compose up -d
```

**To access Grafana or Prometheus:**<br>

Grafana: http\://*<monitoring-server-IP>*:3000 \
Prometheus: http\://*<Your-monitoring-server-IP>*:9090 \
Login: `admin / admin`<br>
- *Add you monitoring host's IP in the http url for Grafana and Prometheus: example: http://192.168.1.100:3000*

---

## 📅 Setting Up a VM to Be Monitored (Client VM)

On each client VM (VM1, VM2, ...):

### Step 1: Install Docker (if not already installed)

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker --now
```

### Step 2: Run Node Exporter

```bash
docker run -d \
  --name node_exporter \
  -p 9100:9100 \
  --restart unless-stopped \
  -v /:/host:ro,rslave \
  prom/node-exporter \
  --path.rootfs=/host
```
*if it doesn't work, try this instead:*

```bash
docker run -d \
  --name node_exporter \
  -p 9100:9100 \
  --restart unless-stopped \
  prom/node-exporter
```
⚠️ Some panels in the advanced dashboard require Node Exporter to be installed as a system service with specific collectors enabled:
- --collector.processes
- --collector.systemd
- --collector.tcpstat
...
These are not supported in Docker-based Node Exporter deployments.
Instead run node exporter directly on the monitored host as:

```bash
# 1. Download Node Exporter
cd /opt
sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
sudo tar -xzf node_exporter-1.8.1.linux-amd64.tar.gz
sudo mv node_exporter-1.8.1.linux-amd64 node_exporter

# 2. Create a systemd service with extra collectors
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
ExecStart=/opt/node_exporter/node_exporter \\
  --collector.systemd \\
  --collector.processes \\
  --collector.tcpstat \\
  --collector.interrupts \\
  --collector.hwmon

[Install]
WantedBy=default.target
EOF

# 3. Enable and start the exporter
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

```

---

## ➕ Adding a New VM Later

1. On VM client: run Node Exporter (see above)
2. On VM1(monitoring server):
   - Edit `vm_list.txt` to add the new VM's IP in a new line
   - Regenerate config: `./generate-prometheus-config.sh`
   - Restart Prometheus:
     ```bash
     docker-compose restart prometheus
     ```
3. The new VM will appear in Grafana's instance dropdown automatically.

---

## 📊 Dashboards

This stack includes mainly two pre-configured Grafana dashboards adapted from [rfmoz/grafana-dashboards](https://github.com/rfmoz/grafana-dashboards):

### ✅ Main Dashboard (`node-main-dashboard.json`)

- Provides essential system metrics:
  - CPU usage
  - Memory consumption
  - Disk usage
  - Network I/O
  - and more
- Works **out of the box** with default Node Exporter setup (e.g., Docker-based).
- Ideal for simple and majority of setups.

### 🚀 Advanced Dashboard (`node-advanced-dashboard.json`)

- Includes **additional insights** such as:
  - detailed kernel/system-level metrics
  - Hardware monitoring (fan speeds, temperatures)
  - Interrupt stats, TCP socket metrics
- Requires running **Node Exporter directly on each monitored VM** (not via Docker) with previously mentioned flags enabled.
- Recommended for **production-grade monitoring** or when full system visibility is needed.
  
Use the **instance** dropdown at the top of Grafana to filter by VM.

