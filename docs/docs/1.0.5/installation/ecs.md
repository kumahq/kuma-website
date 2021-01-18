# ECS

::: tip
NOTE:

All instruction here are for illustrating Kuma capabilities in a non-production deployments. The demo Cloudformation scripts
as parametrised and exploring these parameters is highly recommended before considering Kuma in production.
Also, please check the security notes throughout this document
:::

## Preparation

### Download the example Cloudformation scripts

The example [Cloudformation](https://aws.amazon.com/cloudformation/) scripts are hosted in the main [github repo](https://github.com/kumahq/kuma/tree/1.0.5/examples/ecs). As a preparatory step we'll download these locally:

```shell
export KUMA_VERSION=1.0.5
mkdir ecs && cd ecs
curl --location --output - https://github.com/kumahq/kuma/archive/${KUMA_VERSION}.tar.gz | tar -z --strip 3 --extract --file=- "./kuma-${KUMA_VERSION}/examples/ecs/*yaml"
```

This snippet, will create a folder named `ecs` and populate it with the contents of the relevant ECS examples folder from the git repo.

::: tip
Before continuing with the next steps, make sure to have AWS CLI [installed](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).
:::

### Installing the VPC

The first step is to install the `kuma` VPC.

```shell
aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --stack-name kuma-vpc \
    --template-file kuma-vpc.yaml
```

## Installing the `kuma-cp`

### Control plane
Depending on the desired setup, we can choose from Standalone or Multizone (Global plus Remote) control plane setup.

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Standalone"
The command to deploy the `kuma-cp` stack in the standalone mode is as follows

```shell
aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --stack-name kuma-cp \
    --template-file kuma-cp-standalone.yaml \
    --parameter-overrides AllowedCidr=0.0.0.0/0
```

:::
::: tab "Global"

Deploying a global control plane is simple as it does not have many setting to tune.

```shell
aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --stack-name kuma-cp-global \
    --template-file kuma-cp-global.yaml \
    --parameter-overrides AllowedCidr=0.0.0.0/0
```

:::
::: tab "Remote"
Setting up a remote `kuma-cp` is a two step process. First, deploy the kuma-cp itself:

```shell
aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --stack-name kuma-cp \
    --template-file kuma-cp-remote.yaml \
    --parameter-overrides AllowedCidr=0.0.0.0/0
```

This will also deploy the Kuma Ingress which is needed for the cross-zone communication.

:::
::::


::: tip
The example deployment above will allow access to the kuma-cp exposed services to all IPs, in production we should change `--parameter-overrides AllowedCidr=0.0.0.0/0` to point to a more restricted subnet that will be used to administer 
:::

To remove the `kuma-cp` stack use:
```shell
aws cloudformation delete-stack --stack-name kuma-cp
```


### Kuma DNS

The services within the Kuma mesh are exposed through their names (as defined in the `kuma.io/service` tag) in the `.mesh` DNS zone. In the default workload example that would be `httpbin.mesh`.
Run the following command to create the necessary Forwarding rules in Route 53 and leverage the integrated DNS server in `kuma-cp`.

```shell
aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --stack-name kuma-dns \
    --template-file kuma-dns.yaml \
    --parameter-overrides \
      DNSServer=<kuma-cp-ip>
```

The `<kuma-cp-ip>`, shall be taken from the AWS ECS web console, it maybe both the public and the private IP. In case of a multizone deployment, we should use Remote CP IP.

Note: We strongly recommend exposing the Kuma-CP instances behind a load balancer, and use that IP as the `DNSServer` parameter. This will ensure a more robust operation during upgrades, restarts and re-configurations. 


## Workload setup

The provided example Cloudformation script will run a sample httpbin application on port 80, with `kuma-dp` sidecar attached to it.

### Generate the token

The `workload` template provides a basic example how `kuma-dp` can be run as a sidecar container alongside an arbitrary, single port service container.
In order to run `kuma-dp` container, we have to issue an access token. The latter can be generated using the Admin API of the Kuma CP.

In this example we'll show the simplest form to generate it by executing this command alongside the `kuma-cp`. For this we need to have `<kuma-cp-ip>` as it shows in AWS ECS console:
```shell
ssh root@<kuma-cp-ip> "wget --header='Content-Type: application/json' --post-data='{\"mesh\": \"default\"}' -qO- http://localhost:5681/tokens"
```

When asked, supply the default password `root`.

The generated token is valid for all Dataplanes in the `default` mesh. Kuma also [allows](https://kuma.io/docs/1.0.5/documentation/security/#data-plane-proxy-authentication) to generate tokens based
on Dataplane's Name and Tags.

::: tip

✋ SECURITY NOTE:

Kuma allows much more advanced and secure way to expose the `/tokens` endpoint. For this it needs to have `HTTPS` endpoint configured
on port `5682` as well as client ceritificate setup for authentication. The full procedure is available in Kuma Security documentation
[Data plane proxy authentication](https://kuma.io/docs/1.0.5/documentation/security/#data-plane-proxy-to-control-plane-communication),
[User to control plane communication](https://kuma.io/docs/1.0.5/documentation/security/#user-to-control-plane-communication)
:::

### Deploy the workload and the sidecar

Prepare the token generated in the previous step and supply it as `<token>` in the examples

:::: tabs :options="{ useUrlFragment: false }"
::: tab "Standalone"

```shell
aws cloudformation deploy \
    --capabilities CAPABILITY_IAM \
    --stack-name workload \
    --template-file workload.yaml \
    --parameter-overrides \
      DesiredCount=2 \
      DPToken="<token>"
```

:::
::: tab "Multizone Remote"

```shell
aws cloudformation deploy \
--capabilities CAPABILITY_IAM \
--stack-name workload \
--template-file workload.yaml \
--parameter-overrides \
DesiredCount=2 \
DPToken="<token>" \
CPAddress="https://zone-1-controlplane.kuma.io:5678"
```

The `CPAddress` value is the default in the supplied remote CP example, however this should be changed to whatever matches the concrete example.

:::
::::


The `workload` template has a lot of parameters, so it can be customized for many scenarios, with different workload images, service name and port etc. Find more information in the template itself.
