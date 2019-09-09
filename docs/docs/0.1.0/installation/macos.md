# macOS

To install and run Kuma on **macOS** execute the following steps:

## 1. Download Kuma

You can download Kuma from [here]() or by running:

```sh
$ wget downloads.kuma.io/0.1.0/kuma-linux.amd64.tar.gz
```

You can extract the archive and check the contents by running:

```sh
$ tar xvzf kuma-linux.amd64.tar.gz
$ ls
envoy		kuma-cp		kuma-dp		kuma-injector	kumactl
```

As you can see Kuma already ships with an [envoy](http://envoyproxy.io) executable ready to use.

## 2. Run Kuma

To run Kuma execute:

```sh
$ kuma-cp run
```

