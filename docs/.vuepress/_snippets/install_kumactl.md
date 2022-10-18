To run Kuma on Kubernetes, you need to download the Kuma cli (`kumactl`) on your machine.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Script"

You can run the following script to automatically detect the operating system and download Kuma:

<div class="language-sh">
<pre><code>curl -L https://kuma.io/installer.sh | VERSION={{ $page.latestVersion }} sh -</code></pre>
</div>

You can omit the `VERSION` variable to install the latest version. 
:::
::: tab "Direct Link"

You can also download the distribution manually. Download a distribution for the **client host** from where you will be executing the commands to access Kubernetes:

* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-centos-amd64.tar.gz'">CentOS</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-rhel-amd64.tar.gz'">RedHat</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-debian-amd64.tar.gz'">Debian</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-ubuntu-amd64.tar.gz'">Ubuntu</a>
* <a :href="'https://download.konghq.com/mesh-alpine/kuma-' + $page.latestVersion + '-darwin-amd64.tar.gz'">macOS</a> or run `brew install kumactl`

and extract the archive with `tar xvzf kuma-{{ $page.latestVersion }}.tar.gz`
:::
::::

Once downloaded, you will find the contents of Kuma in the `kuma-{{ $page.latestVersion }}` folder. In this folder, you will find - among other files - the `bin` directory that stores the executables for Kuma, including the CLI client [`kumactl`](../explore/cli.md).

::: tip
**Note**: On Kubernetes - of all the Kuma binaries in the `bin` folder - we only need `kumactl`.
:::

So we enter the `bin` folder by executing: `cd kuma-{{ $page.latestVersion }}/bin`

We suggest adding the `kumactl` executable to your `PATH` (by executing: `PATH=$(pwd):$PATH`) so that it's always available in every working directory. Or - alternatively - you can also create link in `/usr/local/bin/` by executing:

```sh
ln -s kuma-{{ $page.latestVersion }}/bin/kumactl /usr/local/bin/kumactl
```
