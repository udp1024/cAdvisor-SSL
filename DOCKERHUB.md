# cAdvisor with Native SSL / TLS Support (Multi-Arch)

[![GitHub Release](https://img.shields.io/github/v/release/udp1024/cAdvisor-SSL?color=blue&label=release)](https://github.com/udp1024/cAdvisor-SSL/releases)
[![Architectures](https://img.shields.io/badge/Architectures-linux%2Famd64%20%7C%20linux%2Farm64-blue.svg)](https://hub.docker.com/r/udp1024/cadvisor-ssl)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/udp1024/cAdvisor-SSL/blob/main/LICENSE)

An enterprise-ready, enhanced distribution of Google's **[cAdvisor](https://github.com/google/cadvisor)** with **native SSL/TLS and Mutual TLS (mTLS) support**, automated upstream release tracking, smart container healthchecks, and native multi-architecture builds for both **x86_64 (amd64)** and **ARM64**.

GitHub Source: [https://github.com/udp1024/cAdvisor-SSL](https://github.com/udp1024/cAdvisor-SSL)

---

## 🖥️ Supported Architectures (Multi-Arch)

Every image tag is built and pushed as an **OCI multi-platform manifest list**. When you execute `docker pull` or `docker run`, Docker automatically selects and runs the binary tailored for your host CPU architecture:

| Architecture | Platform Tag | Supported Processors & Environments |
| :--- | :--- | :--- |
| **AMD64 / x86_64** | `linux/amd64` | Intel Xeon / Core, AMD EPYC / Ryzen, Standard Cloud VMs (AWS EC2, Google Compute Engine, Azure VMs, Hetzner, Bare Metal) |
| **ARM64 / AArch64** | `linux/arm64` | AWS Graviton (c6g, c7g, m6g, t4g), Apple Silicon (M1/M2/M3/M4 via Docker Desktop), Ampere Altra, Raspberry Pi 4 / 5 (64-bit OS) |

### Inspect Manifest
You can verify the multi-platform manifest directly from your terminal:
```bash
docker buildx imagetools inspect udp1024/cadvisor-ssl:latest
```

---

## 💡 Why cAdvisor-SSL?

### The Problem with Vanilla cAdvisor
Google's upstream cAdvisor daemon serves metrics (`/metrics`) and its web interface over **unencrypted plaintext HTTP**. 

In modern production environments:
* **Security & Compliance**: Regulations like **PCI-DSS**, **HIPAA**, **SOC 2**, and **FedRAMP** prohibit transmitting host and infrastructure telemetry in cleartext. Plaintext metrics expose sensitive host details, kernel statistics, container names, and environment parameters across local networks.
* **Zero Trust Networks**: Modern Kubernetes clusters and hybrid architectures require all intra-cluster communications to be encrypted in transit.

### Why Native SSL vs. Sidecar Proxies?
Traditionally, teams deploy a reverse proxy (such as Nginx, Envoy, or Ghostunnel) as a sidecar in front of cAdvisor. While functional, sidecars introduce major disadvantages:

| Metric | Sidecar Proxy (e.g. Nginx/Envoy) | Native cAdvisor-SSL |
| :--- | :--- | :--- |
| **Containers per Node** | 2 containers (proxy + cAdvisor) | **1 lightweight container** |
| **Memory Footprint** | Additional 50MB - 150MB per node | **0MB extra memory** (built into Go binary) |
| **Port & Loopback Routing** | Complex localhost forwarding | **Direct TLS port binding** |
| **DaemonSet Complexity** | Shared network namespaces, extra configs | **Standard single-container DaemonSet** |
| **Failure Points** | Proxy crashes leave cAdvisor unreachable | **Zero intermediary failure points** |

---

## 🔒 SSL / TLS Command-Line Flags

| Flag | Default | Description |
| :--- | :--- | :--- |
| `-tls_cert_file` | `""` | Path to server SSL/TLS certificate (PEM format). Required for HTTPS. |
| `-tls_key_file` | `""` | Path to server SSL/TLS private key (PEM format). Required for HTTPS. |
| `-tls_client_ca_file` | `""` | *(Optional)* Path to CA certificate pool for **Mutual TLS (mTLS)** verification. |
| `-tls_min_version` | `"1.2"` | *(Optional)* Minimum acceptable TLS version: `"1.2"` or `"1.3"`. |

> **Note:** If `-tls_cert_file` and `-tls_key_file` are omitted, cAdvisor starts in standard HTTP mode on port `8080`.

---

## 🚀 Quick Start Examples

### 1. Docker Run

```bash
docker run -d \
  --name=cadvisor-ssl \
  --restart=always \
  --privileged \
  --device=/dev/kmsg \
  -p 8443:8443 \
  -v /:/rootfs:ro \
  -v /var/run:/var/run:ro \
  -v /sys:/sys:ro \
  -v /var/lib/docker/:/var/lib/docker:ro \
  -v /dev/disk/:/dev/disk:ro \
  -v /etc/cadvisor-certs:/etc/cadvisor-certs:ro \
  udp1024/cadvisor-ssl:latest \
    -port=8443 \
    -tls_cert_file=/etc/cadvisor-certs/cadvisor.crt \
    -tls_key_file=/etc/cadvisor-certs/cadvisor.key
```

Verify your HTTPS endpoint:
```bash
# Test healthz
curl -k https://localhost:8443/healthz

# Test Prometheus metrics
curl -k https://localhost:8443/metrics
```

---

### 2. Docker Compose

```yaml
version: '3.8'

services:
  cadvisor:
    image: udp1024/cadvisor-ssl:latest
    container_name: cadvisor-ssl
    restart: unless-stopped
    privileged: true
    devices:
      - /dev/kmsg
    ports:
      - "8443:8443"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
      - ./certs:/etc/cadvisor-certs:ro
    command:
      - -port=8443
      - -tls_cert_file=/etc/cadvisor-certs/cadvisor.crt
      - -tls_key_file=/etc/cadvisor-certs/cadvisor.key
      - -tls_min_version=1.3
```

---

### 3. Prometheus Scrape Configuration (`prometheus.yml`)

#### Standard HTTPS Scraping:
```yaml
scrape_configs:
  - job_name: 'cadvisor-ssl'
    scheme: https
    static_configs:
      - targets: ['node1.example.com:8443', 'node2.example.com:8443']
    tls_config:
      ca_file: /etc/prometheus/ca.crt
      # If using self-signed certs without private CA:
      # insecure_skip_verify: true
```

#### Mutual TLS (mTLS) Scraping:
```yaml
scrape_configs:
  - job_name: 'cadvisor-mtls'
    scheme: https
    static_configs:
      - targets: ['node1.example.com:8443']
    tls_config:
      ca_file: /etc/prometheus/ca.crt
      cert_file: /etc/prometheus/client.crt
      key_file: /etc/prometheus/client.key
```

---

## 🤖 Automated Upstream Release Tracking

This distribution does not require manual maintenance. A daily GitHub Actions workflow:
1. Detects new official Google cAdvisor release tags via the GitHub API.
2. Automatically rebases our SSL patch onto Google's new tag.
3. Builds native multi-arch images (`linux/amd64` and `linux/arm64`) using Docker Buildx and QEMU.
4. Pushes matching `<version>-ssl` and `latest` tags to Docker Hub and GHCR.
5. In case of upstream merge conflicts, automatically aborts the rebase to guarantee production stability and opens an alert Issue.

---

## License & Credits

* Base cAdvisor is copyright Google Inc. and licensed under the [Apache License 2.0](https://github.com/google/cadvisor/blob/master/LICENSE).
* SSL / TLS enhancement maintained by [udp1024](https://github.com/udp1024/cAdvisor-SSL).
