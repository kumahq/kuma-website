---
title: Systemd
content_type: how-to
---

When using {{site.mesh_product_name}} on VMs it is recommended to use a process manager like systemd.
Here are examples of systemd configurations

## kuma-cp

```
[Unit]
Description = Kuma Control Plane
After = network.target
Documentation=https://kuma.io

[Service]
User=kuma
Environment=KUMA_MODE=standalone
ExecStart = /path/to/kuma/bin/kuma-cp run --config-file=/home/kuma/cp-config.yaml
# if you need your Control Plane to be able to handle a non-trivial number of concurrent connections
# (a total of both incoming and outgoing connections), you need to set proper resource limits on
# the `kuma-cp` process, especially maximum number of open files.
#
# it happens that `systemd` units are not affected by the traditional `ulimit` configuration,
# and you must set resource limits as part of `systemd` unit itself.
#
# to check effective resource limits set on a running `kuma-cp` instance, execute
#
#   $ cat /proc/`pgrep kuma-cp`/limits
#
#   Limit                     Soft Limit           Hard Limit           Units
#   ...
#   Max open files            1024                 4096                 files
#   ...
#
# for Kuma demo setup, we chose the same limit as `docker` and `containerd` set by default.
# See https://github.com/containerd/containerd/issues/3201
LimitNOFILE=1048576
Restart=always
RestartSec=1s
# disable rate limiting on start attempts
StartLimitIntervalSec=0
StartLimitBurst=0

[Install]
WantedBy = multi-user.target
```

## kuma-dp

```
[Unit]
Description=Kuma data plane proxy
After=network.target
Documentation=https://kuma.io

[Service]
User=kuma
ExecStart=/home/kuma/kong-mesh-1.9.1/bin/kuma-dp run \
  --cp-address=https://<kuma-cp-address>:5678 \
  --dataplane-token-file=/home/kuma/echo-service-universal.token \
  --dataplane-file=/home/kuma/dataplane-notransparent.yaml \
  --ca-cert-file=/home/kuma/ca.pem
Restart=always
RestartSec=1s
# disable rate limiting on start attempts
StartLimitIntervalSec=0
StartLimitBurst=0

[Install]
WantedBy=multi-user.target
```
