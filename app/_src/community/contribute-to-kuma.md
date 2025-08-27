---
title: Contribute to Kuma
---

There are multiple ways to make an impact in Kuma

## Community

You can join the Slack channel or the community meetings as shown in the [community section](/community).

## Documentation

You can edit this documentation. Checkout the [contributing](https://github.com/kumahq/kuma-website/blob/master/CONTRIBUTING.md)  documentation on how to get started.

## Core Code

Most of Kuma is in [Go](https://go.dev/). Checkout the [contributing](https://github.com/kumahq/kuma/blob/master/CONTRIBUTING.md) documentation on how to get started.

## GUI Code

The UI is in [Vue.js](https://vuejs.org/). Checkout the [contributing](https://github.com/kumahq/kuma-gui/blob/master/CONTRIBUTING.md) documentation on how to get started.

## Testing unreleased versions

Kuma publishes new binaries for every commit.
There's a small script to download the latest preview version:

```shell
curl -L https://kuma.io/installer.sh | VERSION=preview sh -
```

{% tip %}
If you already know the version you want to test you can run:

```shell
curl -L https://kuma.io/installer.sh | VERSION=0.0.0-preview.v385ed4cc5 sh -
```

or you can use this helm command:

```shell
helm upgrade --install --create-namespace --namespace {{site.mesh_namespace}} {{ site.mesh_helm_install_name }} {{ site.mesh_helm_repo }} \
  --set {{site.set_flag_values_prefix}}controlPlane.image.tag="0.0.0-preview.v385ed4cc5" \
  --set {{site.set_flag_values_prefix}}dataPlane.image.tag="0.0.0-preview.v385ed4cc5" \
  --set {{site.set_flag_values_prefix}}dataPlane.initImage.tag="0.0.0-preview.v385ed4cc5" \
  --set {{site.set_flag_values_prefix}}kumactl.image.tag="0.0.0-preview.v385ed4cc5"
```

{% endtip %}

It outputs:

```shell
Getting release

INFO	Welcome to the Kuma automated download!
INFO	Kuma version: 0.0.0-preview.vbda3bc4bd
INFO	Kuma architecture: amd64
INFO	Operating system: darwin
INFO	Downloading Kuma from: https://packages.konghq.com/public/kuma-binaries-preview/raw/names/kuma-darwin-amd64/versions/bda3bc4bd/kuma-0.0.0-preview.vbda3bc4bd-darwin-amd64.tar.gz
```

You then run kumactl with:

```shell
./kuma-0.0.0-preview.4d3a9fd03/bin/kumactl
```

Note that the version contains the commit short-hash which is useful if you open issues.
