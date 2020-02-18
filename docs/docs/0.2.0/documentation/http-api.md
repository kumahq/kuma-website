# HTTP API

Kuma ships with a RESTful HTTP interface that you can use to retrieve the state of your configuration and policies on every environment, and when running on Universal mode it will also allow to make changes to the state. On Kubernetes, you will use native CRDs to change the state in order to be consistent with Kubernetes best practices.

::: tip
**CI/CD**: The HTTP API can be used for infrastructure automation to either retrieve data, or to make changes when running in Universal mode. The [`kumactl`](#kumactl) CLI is built on top of the HTTP API, which you can also access with any other HTTP client like `curl`.
:::

By default the HTTP API is listening on port `5681`. The endpoints available are:

* `/meshes`
* `/meshes/{name}`
* `/meshes/{name}/dataplanes`
* `/meshes/{name}/dataplanes/{name}`

You can use `GET` requests to retrieve the state of Kuma on both Universal and Kubernetes, and `PUT` and `DELETE` requests on Universal to change the state.

::: tip
The [`kumactl`](/kumactl) CLI under the hood makes HTTP requests to this API.
:::