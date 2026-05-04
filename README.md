# Grafana Monitoring Stack with Prometheus and Node Exporter

This repository provides a simple monitoring setup for tracking metrics (CPU, memory, disk usage, and more) across multiple Linux machines. It includes pre-configured Grafana dashboards designed for different levels of detail.

The stack uses:

- Grafana for visualization and dashboards  
- Prometheus for collecting and storing metrics  
- Node Exporter for exposing system metrics  

All components run in Docker containers using `docker-compose`.

---

## Project Structure

```
monitoring-project/
├── docker-compose.yml
├── generate-prometheus-config.sh
├── prometheus/
│   ├── prometheus.template.yml
│   └── prometheus.yml (generated)
├── grafana/
│   ├── grafana.ini
│   └── provisioning/
│       ├── dashboards/
│       │   ├── node-main-dashboard.json
│       │   ├── node-advanced-dashboard.json
│       │   └── node-minimal-dashboard.json
│       ├── datasources/
│       │   └── prometheus-datasource.yml
│       └── variables/
│           └── variables.yml
├── vm_list.txt
├── README.md
```

---

## Contents Overview

- `docker-compose.yml`  
  Defines and runs Grafana and Prometheus services  

- `generate-prometheus-config.sh`  
  Generates the Prometheus configuration file from `vm_list.txt`  

- `prometheus/`  
  Contains Prometheus configuration files  

- `prometheus/prometheus.template.yml`  
  Template used to generate the final configuration  

- `prometheus/prometheus.yml`  
  Generated configuration file with actual monitoring targets  

- `grafana/`  
  Grafana configuration and provisioning files  

- `grafana/grafana.ini`  
  Main Grafana configuration (port, authentication, etc.)  

- `grafana/provisioning/dashboards/`  
  Pre-configured Grafana dashboards  

- `grafana/provisioning/datasources/prometheus-datasource.yml`  
  Automatically configures Prometheus as a data source  

- `grafana/provisioning/variables/variables.yml`  
  Defines reusable variables for dashboards  

- `vm_list.txt`  
  List of VM IPs or hostnames to monitor  

---

## Prerequisites

- A Linux machine to run the monitoring stack (for example, Ubuntu Server)  
- Docker and Docker Compose installed  

---

## Running the Monitoring Stack

### 1. Clone the repository

Clone this repository to your monitoring server.

### 2. Add VM IPs

Edit `vm_list.txt` and add one IP address or hostname per line:

```
192.159.29.129
192.159.29.130
```

### 3. Generate Prometheus configuration

```bash
chmod +x generate-prometheus-config.sh
./generate-prometheus-config.sh
```

### 4. Start the stack

```bash
docker-compose up -d
```

### Accessing the services

- Grafana: http://<monitoring-server-ip>:3000  
- Prometheus: http://<monitoring-server-ip>:9090  

Default Grafana login:

```
username: admin
password: admin
```

Replace `<monitoring-server-ip>` with the actual IP of your monitoring server.

---

## Setting Up a Client VM

On each machine you want to monitor:

### 1. Install Docker (if needed)

```bash
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable docker --now
```

### 2. Run Node Exporter

Basic setup using Docker:

```bash
docker run -d \
  --name node_exporter \
  -p 9100:9100 \
  --restart unless-stopped \
  -v /:/host:ro,rslave \
  prom/node-exporter \
  --path.rootfs=/host
```

If that does not work, use:

```bash
docker run -d \
  --name node_exporter \
  -p 9100:9100 \
  --restart unless-stopped \
  prom/node-exporter
```

### Important note

Some advanced dashboard panels require additional collectors that are not available in the Docker version of Node Exporter. These include:

- `--collector.processes`  
- `--collector.systemd`  
- `--collector.tcpstat`  

To enable these, install Node Exporter directly on the host:

```bash
cd /opt
sudo wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
sudo tar -xzf node_exporter-1.8.1.linux-amd64.tar.gz
sudo mv node_exporter-1.8.1.linux-amd64 node_exporter
```

Create a systemd service:

```bash
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
ExecStart=/opt/node_exporter/node_exporter \
  --collector.systemd \
  --collector.processes \
  --collector.tcpstat \
  --collector.interrupts \
  --collector.hwmon

[Install]
WantedBy=default.target
EOF
```

Start the service:

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

---

## Adding a New VM

To add another machine later:

1. Start Node Exporter on the new VM  
2. Add its IP to `vm_list.txt`  
3. Regenerate the Prometheus config:

```bash
./generate-prometheus-config.sh
```

4. Restart Prometheus:

```bash
docker-compose restart prometheus
```

The new VM will automatically appear in Grafana.

---

## Dashboards

This setup includes dashboards adapted from the rfmoz Grafana dashboards project.

### Main Dashboard

- Shows essential system metrics:
  - CPU usage  
  - Memory usage  
  - Disk usage  
  - Network activity  

- Works with the default Node Exporter setup  
- Suitable for most use cases  

### Advanced Dashboard

- Provides deeper system insights:
  - Kernel-level metrics  
  - Hardware monitoring (temperature, fans)  
  - Interrupt and TCP statistics  

- Requires Node Exporter installed directly on the host with extra collectors enabled  
- Better suited for production environments  
