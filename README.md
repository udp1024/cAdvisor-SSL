![cAdvisor](logo.png "cAdvisor")

# cAdvisor with Native SSL/TLS Support

[![Upstream Sync, Rebase & Build](https://github.com/udp1024/cAdvisor-SSL/actions/workflows/rebase-and-build.yml/badge.svg)](https://github.com/udp1024/cAdvisor-SSL/actions/workflows/rebase-and-build.yml)

This repository is an enhanced standalone distribution of Google's [cAdvisor](https://github.com/google/cadvisor) with **native SSL/TLS and mutual TLS (mTLS) support**.

It includes automated upstream tracking: whenever Google publishes a new cAdvisor release, GitHub Actions automatically rebases the SSL patch, compiles, and publishes release containers tagged with the matching Google version (e.g. `v0.51.0-ssl`).

---

## 🔒 SSL / TLS Flags

| Flag | Default | Description |
| :--- | :--- | :--- |
| `-tls_cert_file` | `""` | Path to SSL/TLS certificate (PEM format). Required for HTTPS. |
| `-tls_key_file` | `""` | Path to SSL/TLS private key (PEM format). Required for HTTPS. |
| `-tls_client_ca_file`| `""` | Path to client CA cert pool for **Mutual TLS (mTLS)** verification. |
| `-tls_min_version` | `"1.2"` | Minimum TLS version: `"1.2"` or `"1.3"`. |

> **Note:** If `-tls_cert_file` and `-tls_key_file` are omitted, cAdvisor falls back to standard HTTP mode.

---

## 🚀 Quick Start: Running with SSL

### 1. Docker Run
Mount your certificate and private key into the container:

```bash
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --volume=/etc/ssl/certs/cadvisor.crt:/etc/ssl/certs/cadvisor.crt:ro \
  --volume=/etc/ssl/private/cadvisor.key:/etc/ssl/private/cadvisor.key:ro \
  --publish=8443:8443 \
  --detach=true \
  --name=cadvisor-ssl \
  --privileged \
  --device=/dev/kmsg \
  ghcr.io/udp1024/cadvisor-ssl:latest-ssl \
    -port=8443 \
    -tls_cert_file=/etc/ssl/certs/cadvisor.crt \
    -tls_key_file=/etc/ssl/private/cadvisor.key
```

### 2. Standalone Binary
```bash
./cadvisor \
  -port=8443 \
  -tls_cert_file=/path/to/server.crt \
  -tls_key_file=/path/to/server.key \
  -tls_min_version=1.3
```

### 3. Prometheus Scrape Configuration (`prometheus.yml`)
To scrape metrics over HTTPS:

```yaml
scrape_configs:
  - job_name: 'cadvisor-ssl'
    scheme: https
    static_configs:
      - targets: ['cadvisor.example.com:8443']
    tls_config:
      ca_file: /etc/prometheus/ca.crt
      # Or if using self-signed certs:
      # insecure_skip_verify: true
```

---

## Upstream Google cAdvisor Details

cAdvisor (Container Advisor) provides container users an understanding of the resource usage and performance characteristics of their running containers. It is a running daemon that collects, aggregates, processes, and exports information about running containers. Specifically, for each container it keeps resource isolation parameters, historical resource usage, histograms of complete historical resource usage and network statistics. This data is exported by container and machine-wide.

cAdvisor has native support for [Docker](https://github.com/docker/docker) containers and should support just about any other container type out of the box. We strive for support across the board so feel free to open an issue if that is not the case. cAdvisor's container abstraction is based on [lmctfy](https://github.com/google/lmctfy)'s so containers are inherently nested hierarchically.

#### Quick Start: Running cAdvisor in a Docker Container

To quickly tryout cAdvisor on your machine with Docker, we have a Docker image that includes everything you need to get started. You can run a single cAdvisor to monitor the whole machine. Simply run:

```
VERSION=0.55.1 # use the latest release version from https://github.com/google/cadvisor/releases
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  ghcr.io/google/cadvisor:$VERSION # for versions prior to v0.53.0, use gcr.io/cadvisor/cadvisor instead
```

cAdvisor is now running (in the background) on `http://localhost:8080`. The setup includes directories with Docker state cAdvisor needs to observe.

**Note**: If you're running on CentOS, Fedora, or RHEL (or are using LXC), take a look at our [running instructions](docs/running.md).

We have detailed [instructions](docs/running.md#standalone) on running cAdvisor standalone outside of Docker. cAdvisor [running options](docs/runtime_options.md) may also be interesting for advanced usecases. If you want to build your own cAdvisor Docker image, see our [deployment](docs/deploy.md) page.

For [Kubernetes](https://github.com/kubernetes/kubernetes) users, cAdvisor can be run as a daemonset. See the [instructions](deploy/kubernetes) for how to get started, and for how to [kustomize](https://github.com/kubernetes-sigs/kustomize#kustomize) it to fit your needs.

## Building and Testing

See the more detailed instructions in the [build page](docs/development/build.md). This includes instructions for building and deploying the cAdvisor Docker image.

## Exporting stats

cAdvisor supports exporting stats to various storage plugins. See the [documentation](docs/storage/README.md) for more details and examples.

## Web UI

cAdvisor exposes a web UI at its port:

`http://<hostname>:<port>/`

See the [documentation](docs/web.md) for more details.

## Remote REST API & Clients

cAdvisor exposes its raw and processed stats via a versioned remote REST API. See the API's [documentation](docs/api.md) for more information.

There is also an official Go client implementation in the [client](client/) directory. See the [documentation](docs/clients.md) for more information.

## Roadmap

cAdvisor aims to improve the resource usage and performance characteristics of running containers. Today, we gather and expose this information to users. In our roadmap:

- Advise on the performance of a container (e.g.: when it is being negatively affected by another, when it is not receiving the resources it requires, etc).
- Auto-tune the performance of the container based on previous advise.
- Provide usage prediction to cluster schedulers and orchestration layers.

## Community

Contributions, questions, and comments are all welcomed and encouraged! cAdvisor developers hang out on [Slack](https://kubernetes.slack.com) in the #sig-node channel (get an invitation [here](http://slack.kubernetes.io/)). We also have [discuss.kubernetes.io](https://discuss.kubernetes.io/).

Please reach out and get involved in the project, we're actively looking for more contributors to bring on board!

### Core Team
* [@bobbypage, Google](https://github.com/bobbypage)
* [@iwankgb, Independent](https://github.com/iwankgb)
* [@creatone, Independent](https://github.com/creatone)
* [@dims, VMWare](https://github.com/dims)
* [@mrunalp, RedHat](https://github.com/mrunalp)

### Frequent Collaborators
* [@haircommander, RedHat](https://github.com/haircommander)

### Emeritus
* [@dashpole, Google](https://github.com/dashpole)
* [@dchen1107, Google](https://github.com/dchen1107)
* [@derekwaynecarr, RedHat](https://github.com/derekwaynecarr)
