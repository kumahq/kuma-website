---
title: Concepts
---

In this page we will introduce concepts that are core to understanding Kuma.

## Control Plane

The control-plane is the central management layer of {{ site.product_name }}. It is responsible for configuring and managing the behavior of the data plane,
which handles the actual traffic between services.

## Data-Plane Proxy / Sidecar

The data-plane handles traffic between services.
It connects to the control-plane which computes a configuration specific to it.
The data-plane proxy or Sidecar is the instance of Envoy running alongside the data-plane which will send and receive traffic from the rest of the service mesh.

## Resource

A resource is an object or entity that can be created, managed, and interacted with in {{ site.product_name }}.
Resources are the building blocks that define the behavior and state of your service-mesh.
Each resource is defined as a type of API object that has a specific purpose and is represented by its state and configuration.

A resource is most often expressed as yaml and can have 2 formats:

- `Kubernetes` when the backing control-plane runs on Kubernetes. In this case {{ site.product_name }} resources are defined as Kubernetes Custom Resource Definitions.
- `Universal` in other cases or when accessing resources through {{ site.product_name}}'s REST api.

Resources are most commonly represented in yaml format.

## Policy

Policies are a specific type of Resources which controls the behaviour, security and communication of applications running inside your service mesh.
They can enable traffic management, security, observability and traffic reliability.

Policies always have a clear specific area of impact and goal.
To learn more about [policies checkout the in depth introduction](/docs/{{ page.version }}/policies/introduction).
